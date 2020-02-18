// ["g",[["gmail","","0"],["google maps","","1"],["google.com","","2"],["games","","3"],["glee","","4"],["google earth","","5"],["google translate","","6"],["gamestop","","7"],["gary coleman","","8"],["geico","","9"]],"","","","","",{}]
function extractGoogleSuggestSuggestions(structure) {
	var outSuggestions = '';
	
	
	if (structure.length >= 2) {
		var suggestions = structure[1];
		if (suggestions != null) {
			for (var i = 0; i < suggestions.length; i++) {
				var suggestionStructure = suggestions[i];
				if (suggestionStructure != null && suggestionStructure.length > 1) {
					var txt = suggestionStructure[0];
//					var el = document.createElement('b');
//					el.innerHTML = txt;
					var cleanText = txt; //el.innerText;
					outSuggestions += cleanText + "\n";
				}
			}
		}
	}
	return outSuggestions;
}