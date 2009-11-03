// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function imgswap(img_id)
 {
    if ($(img_id).src.indexOf('down-arrow.png') > 0)
    {
        $(img_id).src = '/images/right-arrow.png';
    } else {
        $(img_id).src = '/images/down-arrow.png';
    }
}