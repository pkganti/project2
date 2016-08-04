$(document).ready(function() {

var scrapedCategorySubmit = function(event){
  console.log('scrapeCategorySubmit()', event.data.tabURL);
  var url = 'http://localhost:3000/extensionbookmark?url=' + encodeURIComponent(event.data.tabURL) + '&title=' + $('#title').val() + '&cuisine=' + $('#cuisine').val() + '&category=' + $('#category').val();
    console.log(url);
    $('#message').html(url);
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.onreadystatechange = function(response) {
        if (xhr.readyState == 4) {
          //console.log(xhr.responseText);

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
};

    chrome.tabs.query({
        currentWindow: true,
        active: true
    }, function(tabs) {

        var currentTab = tabs[0];
        console.log(currentTab);

        var encURL = 'http://localhost:3000/extension?url=' + encodeURIComponent(currentTab.url);
        //  chrome.tabs.create({ url: 'http://localhost:3000/extension?url=' + encURL });
        console.log('scrape', encURL);
        var xhr = new XMLHttpRequest();
        xhr.open("GET", encURL, true);
        xhr.onreadystatechange = function(response) {
            if (xhr.readyState == 4) {
                if (xhr.responseText === 'needtologin') {
                    $('#message').html('');
                    chrome.tabs.create({
                        url: 'http://localhost:3000/'
                    });
                } else if (xhr.responseText === 'alreadyExists'){
                    $('#message').html('This recipe is already in your favorites library!');
                    chrome.tabs.create({
                      url: 'http://localhost:3000/favorites/index'
                    });
                } else if (xhr.responseText.indexOf('http')=== 0) {
                  // the scrape worked! so show a small form for setting category & cuisine
                    $('#message').html('');
                    $('#bookmark').show();
                    $('#title').val(currentTab.title);
                    // $('#message').html('Recipe Added! ');

                    $('#submit').on('click', {tabURL: currentTab.url}, scrapedCategorySubmit);
                    // onclick button event handler was here

                } else {
                  // can't scrape this site, so show a form to create a bookmark instead
                    $('#message').html('');
                    $('#bookmark').show();
                    $('#bookmark2').show();
                    $('#title').val(currentTab.title);
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
                        console.log($('.chosen').attr('src'));

                    });

                    $('#submit').on('click', function() {
                      var bookmark_url = 'http://localhost:3000/extensionbookmark?url=' + encodeURIComponent(currentTab.url)+ '&title=' + $('#title').val() + '&cuisine=' + $('#cuisine').val() + '&category=' + $('#category').val() + '&prep_duration_hour=' + $('#prep_duration_hour').val() + '&prep_duration_mins=' + $('#prep_duration_mins').val() + '&cook_duration_hour=' + $('#cook_duration_hour').val() + '&cook_duration_mins=' + $('#cook_duration_mins').val() + '&images=' + $('.chosen').attr('src');
                        console.log(bookmark_url);
                        $('#message').html(bookmark_url);
                        var xhr = new XMLHttpRequest();
                        xhr.open("GET", bookmark_url, true);
                        xhr.onreadystatechange = function(response) {
                            if (xhr.readyState == 4) {
                              console.log(xhr.responseText);

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
