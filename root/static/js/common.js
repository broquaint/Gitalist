// THIS IS NOT USED - it is in the wrapper.tt as js is not parsed by TT (needed for the c.uri_for)
function compareDiffs(repo, path){
	var f = document.theform;
	if(!repo){
		var repo = "";
	}
	if(!path){
		var path = "";
	}
	var sha1,sha2;
	for(var i=0,len=f.length;i<len;i++){
		if(f[i].name == "sha1_a"){
			if(f[i].checked){
				sha1 = f[i].value;
			}
		}
		if(f[i].name == "sha1_b"){
			if(f[i].checked){
				sha2 = f[i].value;
			}
		}
	}
	document.location.href = [% c.uri_for("/" + repo + "/"+ sha1 + "/diff/" + sha2 + "/" + path) %];
}
