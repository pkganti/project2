$(document).ready(function(){
  chrome.tabs.query({ currentWindow: true, active: true }, function(tabs){

    var currentTab = tabs[0];
    //console.log(currentTab);

     var encURL = 'http://localhost:3000/extension?url=' + encodeURIComponent(currentTab.url);
    //  chrome.tabs.create({ url: 'http://localhost:3000/extension?url=' + encURL });
    console.log(encURL);
    var xhr = new XMLHttpRequest();
    xhr.open("GET", encURL, true);
    xhr.onreadystatechange = function(response) {
     if (xhr.readyState == 4) {
      //  console.log("Made it", xhr.responseText);
       if(xhr.responseText === 'ok') {
         $('#message').html('worked!');
       } else {
         $('#message').html('');
         $('#bookmark').show();
           }
      }
    };
    xhr.send();
  //   $.ajax({
  //     url: encURL
  //   }).done(function(data){
  //     console.log(data);
  //     $('#message').html('worked!');
  //     if(data.status === 'ok') {
  //       alert('Recipe pinned to Palate!');
  //     } else {
  //       //show form html
  //       console.log('epic fail');
  //       $('#message').html('screwed!');
  //
  //     }
  //
  // });
});
});
$('#submit').on('click',function(tab){
var encURL = 'http://localhost:3000/extension?url=' + encodeURIComponent(currentTab.url);

var bookmark_url = 'http://localhost:3000/extension?url=' + encURL + '&title=' + ('#title').val() + '&cuisine=' + ('#cuisine').val() + '&category=' + ('#category').val() + '&prep_duration_hour=' + ('#prep_duration_hour').val() + '&prep_duration_mins=' + ('#prep_duration_mins').val() + '&cook_duration_hour=' + ('#cook_duration_hour').val() + '&cook_duration_mins=' + ('#cook_duration_mins').val();
console.log(bookmark_url);
  var xhr = new XMLHttpRequest();
  xhr.open("GET", bookmark_url, true);
  xhr.onreadystatechange = function(response) {
   if (xhr.readyState == 4) {
     if(xhr.responseText === 'ok') {
       $('#bookmark').hide();
       $('#message').html('Added!');
     } else {
       $('#bookmark').hide();
       $('#message').html('Unable to add at this time.');
         }
    }
  };
  xhr.send();
});
