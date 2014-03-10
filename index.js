'use strict';

module.exports = function(originalWriteFunction){
  
  var writing = false;

  var pendingMessages = [];
  var pendingCallbacks = [];

  return function(message,cb){

    if(writing){
      pendingMessages.push(message);
      pendingCallbacks.push(cb);
      return;
    }

    writeMessages(message,function(){
     
      writePendingMessages();

      if(cb){
        cb();
      }
    });

  };

  function writeMessages(messages,cb){

    writing = true;

    originalWriteFunction(messages,function(){
      writing = false;

      if(cb) {
        cb();
      }
    });
  }

  function writePendingMessages(){

    if(!pendingMessages){
      return;
    }

    var messages = pendingMessages;
    pendingMessages = [];

    var callbacks = pendingCallbacks;
    pendingCallbacks = [];

    writeMessages(messages,function(){
      callbacks.forEach(function(cb){
        if(cb){
          cb();
        }
      });
    });
  }
}