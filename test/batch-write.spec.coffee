batchWrite = require('..')

describe 'Batch Write', ->
  
  it 'exports a function', ->
    batchWrite.should.be.a('function')

  DUMMY_WRITE_FUNCTION = (message,callback)->
    if callback then setImmediate(callback)
    
  
  it 'should return a function', ->
    fn = batchWrite(DUMMY_WRITE_FUNCTION)
    fn.should.be.a('function')

  it 'accepts a function that takes a message and a callback', ->
    fn = batchWrite( DUMMY_WRITE_FUNCTION )

  it 'the function returned should accept a message and pass it to the function specified in the setup call', (done) ->
    originalWriteFunction = ()->
      done()

    fn = batchWrite(originalWriteFunction)
    fn('message')

  it 'the function returned calls its callback once the original write is done', (done) ->
    originalWriteFunction = (message,cb)->
      setImmediate(cb)

    fn = batchWrite(originalWriteFunction)
    fn('message', done)

  it 'should not call the original write function again before it returns', (done)->
    writeInProgress = no

    originalWriteFunction = (message,cb)->
      throw new Error("Still writing") if writeInProgress
      writeInProgress = yes

      setImmediate ()->
        writeInProgress = no
        cb()

    fn = batchWrite(originalWriteFunction)

    fn('a')
    fn('b', done)
  
  it 'should call the write function with an array for all batches queued up while writing', (done)->

    callCount = 0

    originalWriteFunction = (message,cb)->
      callCount++
      switch callCount
        when 1 then message.should.deep.equal(['a'])
        when 2 then message.should.deep.equal(['b','c'])
        
      setImmediate(cb)

    fn = batchWrite(originalWriteFunction)

    fn('a')
    fn('b')
    fn('c', done)

  it 'should callback with an error if the underlying write failed', (done)->
    failingWriteFunction = (message,cb)->
      setImmediate( ()->cb('Could not write') )

    fn = batchWrite(failingWriteFunction)

    fn 'message', (err)->
      err.should.not.be.null
      done()


  it 'should fail each single write even when writing an array of messages with the original write function', (done)->
    failingWritingArraysFunction = (message,cb)->
      if Array.isArray(message)
        setImmediate( ()->cb('Could not write') )
      else
        setImmediate(cb)

    failCount = 0

    fn = batchWrite(failingWritingArraysFunction)

    fn('first')
    fn 'second which is batched', (err)->
      handleCallback(err)
    fn 'third message which is batched with the second message', (err)->
      handleCallback(err)

    handleCallback = (err)->
      failCount++
      err.should.not.be.null      
      
      if failCount is 2
        done()

  it 'is possible to define a function to call to pass the batch through before passing the result on to the write function', (done)->
    transformFunction = (batch)->
      done()

    fn = batchWrite(DUMMY_WRITE_FUNCTION, {transform:transformFunction})
    fn('first')    

  it 'uses the output of the transform function as input to the write function', (done)->
    transformFunction = (batch)->'transformed'
    writeFunction = (message)->
      message.should.equal('transformed')
      done()

    fn = batchWrite(writeFunction, {transform:transformFunction})
    fn('first')

  it 'returns true when the number of messages in progress is less than the \'maxPending\' option', ->
    fn = batchWrite(DUMMY_WRITE_FUNCTION, {maxPending:10})
    fn('first').should.be.true

  it 'returns true when the number of messages in progress is less than the \'maxPending\' option when writing multiple messages', ->
    fn = batchWrite(DUMMY_WRITE_FUNCTION, {maxPending:10})

    for i in [1..9]
      fn(i).should.be.true


  it 'return false as soon as more messages are pending than defined in maxPending', ->
    fn = batchWrite(DUMMY_WRITE_FUNCTION, {maxPending:2})

    fn(1).should.be.true
    fn(2).should.be.true
    fn(3).should.be.false

  it 'return false as soon as more messages are pending than defined in maxPending when writing multiple batches sequentially', (done) ->
    fn = batchWrite(DUMMY_WRITE_FUNCTION, {maxPending:2})

    fn(1)
    fn 2, ()->
      fn('2b').should.be.true
      fn('2c').should.be.true
      fn('2d').should.be.false
      done()
      