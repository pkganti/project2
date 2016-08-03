chrome.runtime.onMessage.addListener(function (msg, sender, sendResponse) {
    if (msg.text === 'get_images') {
        var images = [];
        // console.log('in content script');
        for(var i = 0; i < document.images.length; i++){
          if (document.images[i].naturalWidth >= 300 && document.images[i].naturalHeight >= 200) {
            var image_url = document.images[i].src;
            var ext = image_url.split('?')[0];   // remove querystring
            ext = ext.substr(ext.lastIndexOf('.') + 1).toLowerCase();
            if (ext === "jpg" || ext === "jpeg" || ext === "png" || ext === "gif"){
              images.push(image_url);
              console.log(image_url);
            }


          }
        }
        sendResponse(images);
    }
});
