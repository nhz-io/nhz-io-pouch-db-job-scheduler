# PouchDB Job Scheduler (replicate/sync)

[![Travis Build][travis]](https://travis-ci.org/nhz-io/nhz-io-pouch-db-job-scheduler)
[![NPM Version][npm]](https://www.npmjs.com/package/@nhz.io/pouch-db-job-scheduler)

## Install

```bash
npm i -S @nhz.io/pouch-db-job-scheduler
```

## Usage

* Extend `Scheduler` class with your desired behaviour
* `Scheduler` extends [p-queue], so interface is the same essentially with some additions
* constructor `opts` should include `PouchDB` property (will be copied to instance)

```js
const PouchDB = require 'pouchdb'
const Scheduler = require('@nhz.io/pouch-db-job-scheduler')
const replicate = require('@nhz.io/pouch-db-replication-job')

class MyScheduler extends Scheduler {
  /* ... */
}

const scheduler = new MyScheduler({ PouchDB, concurrency: 1 })

scheduler.addAll([ replicate({}, 'http://foo', 'foo'), replicate({}, 'foo', 'bar'), /* ... */ ])

/* ... */
```

## Literate Source

### Import

    PQueue = require 'p-queue'

### Scheduler

    class Scheduler extends PQueue

      constructor: (opts) ->
        super opts

        @PouchDB = opts?.PouchDB or PouchDB

      add: (run, args...) -> super (@prepare run), args...

> Prepare job for run (Binding cleanup upon completion/fail)

      prepare: (run) -> () =>

        job = run { @PouchDB }

        job.then () => @cleanup job

        job.catch => @cleanup job

        job

> Need to call stop on any pouchdb job to unbind listeners

      cleanup: (job) ->

        job.stop()

        null


### Exports

    module.exports = Scheduler

## Tests

    test = require 'tape-async'

    PouchDB = require 'pouchdb-memory'
    PQueue = require 'p-queue'

    replicate = require '@nhz.io/pouch-db-replication-job'

    mkdb = (i, n = 0) ->

      db = new PouchDB "db-#{ i }"

      await db.put { _id: "doc-#{ i + 1 }" } for i in [0...n]

      db

> Base Scheduler test

    test 'Scheduler', (t) ->

      rand = Math.random().toString().slice(3)

      scheduler = new Scheduler ({ concurrency: 1 })

      source = await mkdb 1 + rand, 2

      target = await mkdb 5 + rand

      jobs = for i in [1..4] then replicate {}, "db-#{ i + rand }", await mkdb i + 1 + rand

      await scheduler.addAll jobs

      t.deepEqual await source.allDocs(), await target.allDocs()

## Version 0.1.1

## License [MIT](LICENSE)

[travis]: https://img.shields.io/travis/nhz-io/nhz-io-pouch-db-job-scheduler.svg?style=flat
[npm]: https://img.shields.io/npm/v/@nhz.io/pouch-db-job-scheduler.svg?style=flat

[p-queue]: https://github.com/sindresorhus/p-queue
