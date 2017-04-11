const express = require('express');
const bodyParser = require('body-parser');
const fileUpload = require('express-fileupload');
const uuid = require('uuid');
const crypto = require('crypto');
const request = require('request');
const cookieSession = require('cookie-session');

const rootDir = './frontend';
const staticDir = process.env.NON_LOCAL ? '/srv/static' : `${rootDir}/static`;

const app = express();

// knex
const knex_config = require('../knexfile.js');
const knex = require('knex')(knex_config[process.env.environment]);
knex.migrate.latest(knex_config[process.env.environment]);

//serve static files if developing locally (this route is not reached on servers)
app.use('/static', express.static(staticDir));


const secret = process.env.NON_LOCAL ? process.env.COOKIE_SECRET : 'local';

app.use(cookieSession({
  name: 'session',
  secret: secret,
  httpOnly: true,
  secure: process.env.NON_LOCAL,
  maxAge: 365 * 24 * 60 * 60 * 1000
}));

if (process.env.NON_LOCAL) {
  app.set('trust proxy', 'loopback');
}

const userImagesPath = process.env.NON_LOCAL ? '/srv/static/images' : `${__dirname}/../frontend/static/images`;

const communicationsKey = process.env.COMMUNICATIONS_KEY;
if (!communicationsKey) console.warn("You should have COMMUNICATIONS_KEY for avoine in ENV");

const sebaconAuth = process.env.SEBACON_AUTH;
const sebaconCustomer = process.env.SEBACON_CUSTOMER;
const sebaconUser = process.env.SEBACON_USER;
const sebaconPassword = process.env.SEBACON_PASSWORD;
if (!sebaconAuth ||
    !sebaconCustomer ||
    !sebaconUser ||
    !sebaconPassword) {
  console.warn("You should have SEBACON_* parameters for avoine in ENV");
}

const sebacon = require('./sebaconService')({
  customer: sebaconCustomer, user: sebaconUser,
  password: sebaconPassword, auth: sebaconAuth});

const smtpHost = process.env.SMTP_HOST;
const smtpUser = process.env.SMTP_USER;
const smtpPassword = process.env.SMTP_PASSWORD;
const smtpTls = process.env.SMTP_TLS;
const mailFrom = process.env.MAIL_FROM;
if (!smtpHost || !smtpUser || !smtpPassword || !smtpTls || !mailFrom) {
  console.warn("You should have SMTP_* parameters and MAIL_FROM in ENV");
}
const smtp =
      { host: smtpHost,
        user: smtpUser,
        password: smtpPassword,
        tls: smtpTls === 'true'
      }
const emails = require('./emails')({ smtp, mailFrom, staticDir });

const logon = require('./logonHandling')({ communicationsKey, knex, sebacon });
const util = require('./util')({ knex });
const profile = require('./profile')({ knex, sebacon, util, userImagesPath, emails});
const ads = require('./ads')({ util, knex, emails });

const urlEncoded = bodyParser.urlencoded();
const jsonParser = bodyParser.json();
const textParser = bodyParser.text();
const fileParser = fileUpload();

app.post('/kirjaudu', urlEncoded, logon.login );
app.get('/uloskirjautuminen', logon.logout);

app.get('/api/profiilit/oma', profile.getMe);
app.put('/api/profiilit/oma', jsonParser, profile.putMe);
app.put('/api/profiilit/oma/kuva', fileParser, profile.putImage);
app.put('/api/profiilit/oma/kuva/rajattu', fileParser, profile.putCroppedImage);
app.post('/api/profiilit/luo', profile.consentToProfileCreation);
app.get('/api/profiilit', profile.listProfiles);
app.get('/api/profiilit/:id', profile.getProfile);

app.get('/api/tehtavaluokat', (req, res) => {
  return sebacon.getPositionTitles().then(positions => res.json(Object.values(positions).sort()));
});

app.get('/api/toimialat', (req, res) => {
  return sebacon.getDomainTitles().then(domains => res.json(Object.values(domains).sort()));
});

app.post('/api/ilmoitukset', jsonParser, ads.createAd);
app.get('/api/ilmoitukset/:id', ads.getAd);
app.get('/api/ilmoitukset', ads.listAds);
app.get('/api/ilmoitukset/tradenomilta/:id', ads.adsForUser);
app.post('/api/ilmoitukset/:id/vastaus', jsonParser, ads.createAnswer);


app.get('/api/asetukset', (req, res) => {
  util.userForSession(req).then(dbUser => {
    const settings = {};
    const dbSettings = dbUser.settings || {};
    const trueFallback = value => value === undefined ? true : value;
    settings.emails_for_answers = trueFallback(dbSettings.emails_for_answers);
    settings.emails_for_businesscards = trueFallback(dbSettings.emails_for_businesscards);
    settings.emails_for_new_ads = trueFallback(dbSettings.emails_for_new_ads);
    settings.email_address = dbSettings.email_address || '';
    res.json(settings);
  });
});

app.put('/api/asetukset', jsonParser, (req, res) => {
  util.userForSession(req).then(dbUser => {
    const newSettings = Object.assign({}, dbUser.settings, req.body);
    return knex('users').where({ id: dbUser.id }).update('settings', newSettings);
  }).then(resp => {
    res.sendStatus(200);
  });
})

app.post('/api/kontaktit/:user_id', jsonParser, profile.addContact)

app.post('/api/virhe', textParser, (req, res) => {
  const errorHash = logError(req, req.body);
  res.json(errorHash);
});

app.get('*', (req, res) => {
  res.sendFile('./index.html', {root: staticDir})
});

app.use(function(err, req, res, next) {
  const errorHash = logError(req, err);
  res.status(err.status || 500).send(errorHash);
});

function logError(req, err) {
  const hash = crypto.createHash('sha1');
  hash.update(uuid.v4());
  const errorHash = hash.digest('hex').substr(0, 10);
  console.error(`${errorHash} ${req.method} ${req.url} ↯`, err);
  return errorHash;
}

app.listen(3000, () => {
  console.log('Listening on 3000');
});

