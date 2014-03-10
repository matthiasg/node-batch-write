'use strict';

module.exports = function(originalWriteFunction, options){
  
  var writing = false;

  var pendingMessages = [];
  var pendingCallbacks = [];

  return function(message,cb){

    if(writing){
      pendingMessages.push(message);
      pendingCallbacks.push(cb);
      return hasStillLessMessagesPendingThanAcceptable();
    }

    writeMessages([message],function(err){
     
      writePendingMessages();

      if(cb){
        cb(err);
      }
    });

    return hasStillLessMessagesPendingThanAcceptable();
  };

  function hasStillLessMessagesPendingThanAcceptable(){
    if(options && options.maxPending){
      return pendingMessages.length < options.maxPending;
    } else {
      return true;
    }
  }

  function writeMessages(messages,cb){

    writing = true;

    if(options && options.transform){
      messages = options.transform(messages);
    }

    originalWriteFunction(messages,function(err){
      writing = false;

      if(cb) {
        cb(err);
      }
    });
  }

  function writePendingMessages(){

    if(pendingMessages.length === 0){
      return;
    }

    var messages = pendingMessages;
    pendingMessages = [];

    var callbacks = pendingCallbacks;
    pendingCallbacks = [];

    if(messages.length === 1){
      messages = messages[0];
    }

    writeMessages(messages,function(err){
      callbacks.forEach(function(cb){
        if(cb){
          cb(err);
        }
      });
    });
  }
}