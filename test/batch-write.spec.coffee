batchWrite = require('..')

describe 'Batch Write', ->
  
  it 'exports a function', ->
    batchWrite.should.be.a('function')

  DUMMY_WRITE_FUNCTION = (message,callback)->
  
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
    
