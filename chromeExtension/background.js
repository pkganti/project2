chrome.browserAction.onClicked.addListener(function(tab){
   //alert('clicked');
   //console.log(tab.url);
   var encURL = 'http://localhost:3000/extension?url=' + encodeURIComponent(tab.url);
  //  chrome.tabs.create({ url: 'http://localhost:3000/extension?url=' + encURL });
  console.log(encURL);
  $.ajax({
    url: encURL
  }).done(function(data){
    console.log(data);
    if(data === true) {
      //success!
    } else {
      //fail!
    }
  });
 });
