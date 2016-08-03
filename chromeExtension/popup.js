$(document).ready(function() {
    chrome.tabs.query({
        currentWindow: true,
        active: true
    }, function(tabs) {

        var currentTab = tabs[0];
        console.log(currentTab);

        var encURL = 'http://localhost:3000/extension?url=' + encodeURIComponent(currentTab.url);
        //  chrome.tabs.create({ url: 'http://localhost:3000/extension?url=' + encURL });
        console.log(encURL);
        var xhr = new XMLHttpRequest();
        xhr.open("GET", encURL, true);
        xhr.onreadystatechange = function(response) {
            if (xhr.readyState == 4) {
                if (xhr.responseText === 'needtologin') {
                    $('#message').html('');
                    chrome.tabs.create({
                        url: 'http://localhost:3000/'
                    });
                } else if (xhr.responseText.indexOf('http')=== 0) {
                    $('#message').html('Recipe Added! ');

                    $('<a>').attr('href', xhr.responseText).html('See it on Palate').on('click', function(){
                      chrome.tabs.create({
                          url: xhr.responseText
                      });
                    }).appendTo('#message');
                } else {
                    $('#message').html('');
                    $('#bookmark').show();
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

                    $('#submit').on('click', function(tab) {
                      var bookmark_url = 'http://localhost:3000/extensionbookmark?url=' + encURL + '&title=' + $('#title').val() + '&cuisine=' + $('#cuisine').val() + '&category=' + $('#category').val() + '&prep_duration_hour=' + $('#prep_duration_hour').val() + '&prep_duration_mins=' + $('#prep_duration_mins').val() + '&cook_duration_hour=' + $('#cook_duration_hour').val() + '&cook_duration_mins=' + $('#cook_duration_mins').val() + '&images=' + $('.chosen').attr('src');
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
