function imgswap(img_id) {
  elem = $('#' + img_id);
	if (elem.attr('src').indexOf('down-arrow.png') > 0)
	{
		elem.attr('src', 'images/right-arrow.png');
	} else {
		elem.attr('src', 'images/down-arrow.png');
	}
}