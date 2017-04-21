/* global describe, beforeEach, afterEach, it */

const chai = require('chai');
const should = chai.should();

const moment = require('moment');
const MockDate = require('mockdate');

const knex_config = require('../../knexfile');
const knex = require('knex')(knex_config['test']);

const util = require('../util')({ knex });
const service = require('./profiles')({ knex, util });

const aDate = new Date('2018-01-13T11:00:00.000Z');

describe('Handle users', function() {

  beforeEach(function(done) {
    knex.migrate.rollback()
      .then(function() {
        knex.migrate.latest()
          .then(function() {
            return knex.seed.run()
              .then(function() {
                done();
              });
          });
      });
  });

  afterEach(function(done) {
    knex.migrate.rollback()
      .then(function() {
        done();
      });
  });


  it('should list users', (done) => {
    service.listProfiles(false).then((users) => {
      users.map(user => user.id).should.include(1);
      done();
    })
  });

  it('should respect limit and offset', (done) => {
    const limit = 0;
    const offset = 0;
    service.listProfiles(false, limit, offset).then((users) => {
      users.should.have.length(0);
      done();
    })
  })

  function insertAndList(sort) {
    MockDate.set(aDate);
    return knex('users').insert({id: 3, remote_id: -3, data: {
      name: 'Ökynomi'
    }, settings: {}, modified_at: moment()}).then(() => {
      return service.listProfiles(false, undefined, undefined, undefined, undefined, undefined, sort)
    })
  }

  it('should sort by activity by default', (done) => {
    insertAndList(undefined).then(users => {
      users.should.have.length(3);
      users[0].id.should.equal(3);
      done();
    })
  });

  it('should sort by activity when asked', (done) => {
    insertAndList('recent').then(users => {
      users.should.have.length(3);
      users[0].id.should.equal(3);
      done();
    })
  });

  it('should sort by name descending', (done) => {
    insertAndList('alphaDesc').then(users => {
      users.should.have.length(3);
      users[0].id.should.equal(3);
      done();
    })
  });

  it('should sort by name ascending', (done) => {
    insertAndList('alphaAsc').then(users => {
      users.should.have.length(3);
      users[2].id.should.equal(3);
      done();
    })
  });

});
