$(document).ready(function() {
  var baseUrl = 'http://localhost:3000'; //the root url
  // var baseUrl = 'http://wdi15project2.herokuapp.com';

var scrapedCategorySubmit = function(event){
  //run function for qualified recipes from a scraped channel (BBC Good Food, Taste, Food Network or AllRecipes)
  var url = baseUrl + '/extensionbookmark?url=' + encodeURIComponent(event.data.tabURL) + '&title=' + $('#title').val() + '&cuisine=' + $('#cuisine').val() + '&category=' + $('#category').val();
  //Build url to pass back title, cuisine and category data via the extensionbookmark route
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.onreadystatechange = function(response) {
        if (xhr.readyState == 4) {
            if (xhr.responseText.indexOf('http')=== 0) {
            // if the json respons is a url, update extension Url to reflect a link to the new successfully added recipe
                $('#bookmark').hide();
                $('#message').html('Recipe Added! ');
                $('<a>').attr('href', xhr.responseText).html('See it on Palate').on('click', function(){
                  chrome.tabs.create({
                      url: xhr.responseText
                  });
                }).appendTo('#message');
            } else {
              //if error occured with adding the recipe provide this message
                $('#bookmark').hide();
                $('#message').html('Unable to add at this time.');
            }
        }
    };
    xhr.send();
};

    chrome.tabs.query({
        currentWindow: true,
        active: true
    }, function(tabs) {
        //chrome's method for retrieving an object consisting of information on the current tab including url
        var currentTab = tabs[0];
        var encURL = baseUrl + '/extension?url=' + encodeURIComponent(currentTab.url);
        //url is sent to the controller via the extension route to check if the user is logged in, browsing a supported site or not, and  checking if the recipe is already in the user's favorites.
        var xhr = new XMLHttpRequest();
        xhr.open("GET", encURL, true);
        xhr.onreadystatechange = function(response) {
            if (xhr.readyState == 4) {
                if (xhr.responseText === 'needtologin') {
                //open new tab to login page if the user is not signed in
                    $('#message').html('');
                    chrome.tabs.create({
                        url: baseUrl
                    });
                } else if (xhr.responseText === 'alreadyExists'){
                //redirect to user's favorites page if the recipe already exists in the user's library.
                    $('#message').html('This recipe is already in your favorites library!');
                    chrome.tabs.create({
                      url: baseUrl + '/favorites/index'
                    });
                } else if (xhr.responseText.indexOf('http')=== 0) {
                  // the scrape worked! so show a small form for setting category & cuisine
                    $('#message').html('');
                    $('#bookmark').show();
                    $('#title').val(currentTab.title);
                    $('#submit').on('click', {tabURL: currentTab.url}, scrapedCategorySubmit);
                    // onclick button event handler was here

                } else {
                  // can't scrape this site, so show a form to create a bookmark instead
                    $('#message').html('');
                    $('#bookmark').show();
                    $('#bookmark2').show();
                    $('#title').val(currentTab.title);
                      //refer to injected content to retrieve qualified photos on the current page
                    chrome.tabs.sendMessage(currentTab.id, {
                        text: 'get_images'
                    }, function(images) {
                        for (var i = 0; i < images.length; i++) {
                            $('<img>').attr('src', images[i]).addClass('candidate').appendTo('#image-results');
                        }
                    });
                    $('body').on('click', 'img', function() {
                        $('img').removeClass("chosen");
                        $(this).addClass("chosen");
                        //add the class chosen to the selected image so it can be used in the recipe library
                    });
                    //for unsupported sites, use the extensionbookmark route to create a new recipe with information in the longer form
                    $('#submit').on('click', function() {
                      var bookmark_url = baseUrl + '/extensionbookmark?url=' + encodeURIComponent(currentTab.url)+ '&title=' + $('#title').val() + '&cuisine=' + $('#cuisine').val() + '&category=' + $('#category').val() + '&prep_duration_hour=' + $('#prep_duration_hour').val() + '&prep_duration_mins=' + $('#prep_duration_mins').val() + '&cook_duration_hour=' + $('#cook_duration_hour').val() + '&cook_duration_mins=' + $('#cook_duration_mins').val() + '&images=' + $('.chosen').attr('src');
                        console.log(bookmark_url);
                        $('#message').html(bookmark_url);
                        var xhr = new XMLHttpRequest();
                        xhr.open("GET", bookmark_url, true);
                        xhr.onreadystatechange = function(response) {
                            if (xhr.readyState == 4) {
                              console.log(xhr.responseText);
                              //when the recipe is added, show the link to the newly added recipe
                                if (xhr.responseText.indexOf('http')=== 0) {
                                    $('#bookmark').hide();
                                    $('#message').html('Recipe Added! ');

                                    $('<a>').attr('href', xhr.responseText).html('See it on Palate').on('click', function(){
                                      chrome.tabs.create({
                                          url: xhr.responseText
                                      });
                                    }).appendTo('#message');

                                } else {
                                    $('#bookmark').hide();
                                    $('#message').html('Unable to add at this time.');
                                }
                            }
                        };
                        xhr.send();
                    });

                } // closes 'else' of Ajax request, i.e. scrape failed
            }
        };
        xhr.send();
    });
});
