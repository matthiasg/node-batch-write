Install 
=======

```
npm install batch-write
```

Usage
=====

```
var batchWrite = require('batch-write');

var write = batchWrite(function(message,cb){
                    fs.appendFile('test.txt',message,{encoding:'utf8'},cb);
                });

```

Overview
========

When dealing with some APIs you might encounter a `write` function that offers a callback once the write is finished.

```
store.write('my message', onWritten);
```

If the API does not allow calling write again until the callback has been executed it, it is essentially a synchronous API. When writing to [kestrel][k] for example, in order to do reliable writes, the writer has to wait until it receives a `STORED` message back.

[k]: https://github.com/twitter/kestrel

When trying to write to that API as fast as possible the only way to reliably write without potentially loosing messages without noticing it, is by writing batches.

```
var messages = ['message 1','message 2'];
store.write(messages);
```

When the individual message are received by e.g. a WebServer individually the batch is not really accessible though, forcing the developer to gather the messages up first before writing the batch, which is what this module helps with.

Now you can write:

```
var writeMessageToStore = batchWrite( function(batch,cb){store.write(batch,cb)} );

writeMessageToStore('message 1',onWritten);
writeMessageToStore('message 2',onWritten);
writeMessageToStore('message 3',onWritten);
writeMessageToStore(['message 4','message 5'],onWritten); // it is still possible to write multiple messages at once. they will become part of a batch
```

It might make sense to define the new function directly on the object though:

```
store.writeWithBatching = batchWrite( function(batch,cb){store.write(batch,cb)} );
```

If the callback really just wraps you could just pass a bound write function of course:

```
store.writeWithBatching = batchWrite( store.write.bind(store) );
```

Options
=======

For convenience some options are possible to be defined.

```
var options = 
        {
            maxBatchSize: 100,
            maxPending: 1000,
            transform: function(batch){ return batch.length+':'+batch.join(':'); },
            retry: 3
        };

store.writeWithBatching = batchWrite( store.write.bind(store), options );
```

How does it work ?
==================

The first write it gets is immediately passed on to the write function as an array with one element. It then asynchronously waits for the callback to be executed. Should any other write calls come in during that time it will queue the message in an array. Once the callback comes back (and no errors where raised), the array is sent.

If a write or a batch write fails all callbacks get called with the error.
If the maximum batch size is exceeded a new array is created internally.

The write function starts returning false as soon as `maxPending` is reached internally. Writers should start backing off then.



Development
===========

Tests
-----

```
npm test
```

Continuous Testing
------------------

The tests can run continuously on file changes when running with e.g. nodemon as already defined as a 'dev' script in the package.json. It can be started with: 

```
npm run-script dev
```

