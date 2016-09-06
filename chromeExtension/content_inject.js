chrome.runtime.onMessage.addListener(function(msg, sender, sendResponse) {
    //inject script when a page is opened
    if (msg.text === 'get_images') {
        var images = [];
        // console.log('in content script');
        for (var i = 0; i < document.images.length; i++) {
            //find images from page and check that the natural width and height is greater than 300x200
            if (document.images[i].naturalWidth >= 300 && document.images[i].naturalHeight >= 200) {
                var image_url = document.images[i].src; // get source url for the qualified photos to display on ext
                var ext = image_url.split('?')[0]; // remove querystring
                ext = ext.substr(ext.lastIndexOf('.') + 1).toLowerCase(); //check that the image file extension is only jpg, jpeg, png or gif to filter out unqualified images
                if (ext === "jpg" || ext === "jpeg" || ext === "png" || ext === "gif") {
                    images.push(image_url); //add src urls for qualified images to the array to be sent back to the extension code
                }

            }
        }
        sendResponse(images);
    }
});
