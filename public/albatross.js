Albatross.prototype.init = function init( options ){
var button = options.button,
    container = options.container,
    date = new Date(),
    obj = this;
    
    // add click event for button
    button.click(function(e){
      container.html('you have clicked me');
      // get form fields
      var currTime = date.getTime();
      
      if( ! Albatross.WORKER_SET ){
        obj.CURRENT_WORKER = new Worker( obj.WORKER_PATH );
        obj.WORKER_SET = true;
        obj.CURRENT_WORKER.postMessage({'method':'sendRequest', 'ajaxurl': obj.AJAXURL, 'content': currTime });
        obj.eventListener();
      }
      else{
        container.html( 'Your request has been submitted, please standby while its being processed.');
      }
      return false;
    });
}

Albatross.prototype.stop = function stop(){
  this.CURRENT_WORKER.postMessage({ 'method':'stop' });
}

Albatross.prototype.eventListener = function eventListener(){
  this.CURRENT_WORKER.addEventListener( 'message', function(e){
    console.log( e.data );
  });
}

Albatross.prototype.getFormData = function getFormData(){
  // get form data to load onto page
  $.get('',{data:'formData', noCache:Math.random()},function( data ){
    console.log( data );
  });
}

Albatross.prototype.setUp = function setUp(){
  this.WORKER_PATH = '/albatross_util.js';
  this.AJAXURL = 'http://ec2-50-19-182-192.compute-1.amazonaws.com:5252/';
  this.WORKER_SET = false;
  this.CURRENT_WORKER = {};
  this.RESPONSE_TEXT = [];
}

function Albatross(){
  this.setUp();
  // this.getFormData();
  return this.init({
    button: $('#reg_button'),
    container: $('#response_container')
  });
}

(function(){
  if( typeof window.Albatross !== undefined && window.jQuery ){
    window.onload = function(){ return new Albatross(); }
  }
}());