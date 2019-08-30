
// window.addEvent('load', function() {
//   new JCaption('img.caption');
// });

$(document).ready(function() {

  // Lightcase
  jQuery('a[data-rel^=lightcase]').lightcase({
    maxHeight: 1000
  });

  // Fix for gallery
  var filters = jQuery('#filters')

  if(filters.length) {
    var notGalleryItems

    filters.find('a').on('click', function(ev) {
      notGalleryItems && notGalleryItems.attr('data-rel', 'lightcase:gallery')
      // jQuery('#lightcase-overlay, #lightcase-loading, #lightcase-case, #lightcase-nav').remove()

      var filterCategory = ev.target.getAttribute('data-filter').replace(/[^a-z0-9\-\_]+/, '')

      var allItems = jQuery('a[data-rel^=lightcase]').unbind().removeData(['items', 'cache'])

      var galleryItems = allItems.filter('[data-categories~=' + filterCategory + ']')
      notGalleryItems = allItems.filter(':not([data-categories~=' + filterCategory + '])').attr('data-rel', '')

      galleryItems.lightcase({
        maxHeight: 1000
      })
    })
  } else {

  }

  var searchResults = jQuery(".search-results")

  if (searchResults.length) {
    var key   = "AIzaSyBIaBFr7Jr8UjP2jdogkyiguV61paPiC34",
        cx    = "017192023017850555155:jn79xmqw5vm",
        query = getParameterByName("searchword")

    jQuery('#searchword').val(query)
    // Add search term
    jQuery(".search-term__query")[0].innerHTML = query

    jQuery.get( "https://www.googleapis.com/customsearch/v1?key=" + key + "&cx=" + cx + "&q=" + query, function(data) {
      // Remove placeholder text
      searchResults[0].innerHTML = ""

      if (data.items && data.items.length) {
        // Add search result items
        jQuery.each(data.items, function(key, item) {
          searchResults.append(searchResultItem(item.title, item.link, item.htmlSnippet))
        })
      } else {
        searchResults.append("Na vámi zadanou frázi nebylo nic nalezeno.")
      }
    });

    function searchResultItem(title, link, snippet) {
      return "<div class='search-results__item'><div><strong><a href='"+link+"'>"+title+"</a></strong></div><div>"+decodeURI(snippet)+"</div></div>"
    }

    function getParameterByName(name, url) {
      if (!url) url = window.location.href;
      name = name.replace(/[\[\]]/g, "\\$&");
      var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
          results = regex.exec(url);
      if (!results) return null;
      if (!results[2]) return '';
      return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
  }

});

jQuery.noConflict()
