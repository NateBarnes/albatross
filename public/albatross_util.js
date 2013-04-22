addEventListener('message', function(e){  
  // Data recieved from event object
  var data = e.data;
  
  switch( data.method ) {
    case 'sendRequest':
      var req = new XMLHttpRequest();
      req.open( "POST", data.ajaxurl, false );
      req.setRequestHeader( 'Content-Type', 'application/x-www-form-urlencoded' );
      req.setRequestHeader( 'Connection', 'keep-alive' );
      req.setRequestHeader( 'Keep-Alive', 'null' );
      req.async = true;
      req.send( JSON.stringify({reqTime:data.content }) );
      req.onprogress = function(e){
        postMessage( {response:req.responseText,status: 'progress'} );
      }
      req.onreadystatechange = function(e){
        if( req.readyState == 4 && req.status == 200 ){
          postMessage( {respose: req.responseText, status: 'complete'} );
        }
      }
    break;
    case 'stop':
      self.close();
    break;
  }

},false);