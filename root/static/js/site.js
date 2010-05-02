function findPos(obj) {
	var curleft = curtop = 0;
	if (obj.offsetParent) {
	  do {
		  curleft += obj.offsetLeft;
		  curtop += obj.offsetTop;
	  } 
	  while (obj = obj.offsetParent);
	  return [curleft,curtop];
	}
}

function setNavClass(el){
	var link_el = document.getElementById("actions_nav_link");
	var offsetAry = findPos(link_el);
	// set position of list
	el.style.left = offsetAry[0]+"px";
	el.style.top = offsetAry[1]+30 +"px";
	el.className+=" actions_nav_list_over";
}

// handles hover sub menus in IE
function startList() {
	if(!document.getElementById("actions_nav_link"))
	    return;
	var navList = document.getElementById("actions_nav_list");
	var navLink = document.getElementById("actions_nav_link");
	// assign event handlers to each element
	navLink.onmouseover=function() {
		setNavClass(navList);
	};
	navList.onmouseover=function() {
		setNavClass(navList);
	};
	navList.onmouseout=function() {
		navList.className=navList.className.replace(" actions_nav_list_over", "");
	};
	navLink.onmouseout=function() {
		navList.className=navList.className.replace(" actions_nav_list_over", "");
	};
}

function uriFor(action, sha1) {
    return jQuery('#' + action + '-uri').text().replace(/\bHEAD\b/, sha1);
}

function switchBranch() {
    var branch = jQuery('#branch-list').val();
    document.location.href = uriFor('current', branch);
}

function compareDiffs(){
    var path     = jQuery('#compare-path').text(),
        baseSha1 = jQuery('#compare-form input[name=sha1_a]:checked').val(),
        compSha1 = jQuery('#compare-form input[name=sha1_b]:checked').val(),
        diffUri  = uriFor('diff', baseSha1);
    document.location.href = diffUri + '/' + compSha1 + (path ? '/' + encodeURIComponent(path) : '');
    return false;
}

function _loadCommitInfo(cells) {
  var cell     = jQuery(cells.shift());
  var filename = cell.find('.js-data').text();
  jQuery.getJSON(uriFor('file_commit_info') + '/' + filename, {}, function(commitInfo) {
    cell.empty();
    cell.html('<a href="'+uriFor('commit', commitInfo.sha1)+'">'+commitInfo.comment+'</a> '+commitInfo.age);
    if(cells.length > 0)
      _loadCommitInfo(cells);
  });
}

function loadCommitInfo() {
  _loadCommitInfo( jQuery('#commit-tree .message').get() );
}

jQuery(function() {
    // Provide sub-nav dropdowns (I think).
    startList();

    // JS up any Compare links
    jQuery('a.compare-link').click(compareDiffs);
    // Change the URL when a branch is selected
    jQuery('#branch-list').change(switchBranch);
    // Wait for image requests to come back first
    jQuery(window).load(loadCommitInfo);
});
