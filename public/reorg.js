js_person_id = 0;
js_person_name = '';
js_option_id = 0;
js_option_label = '';
js_yes = 0;
js_nos = 0;
js_comments = [];

$(document).ready(function(){
		roundCorners();
		newRumor();
		initListeners();
	});

function roundCorners(){
	var settings = configureRoundCorners(10);
	curvyCorners(settings, document.getElementById('yes'));
	curvyCorners(settings, document.getElementById('no'));

	settings = configureRoundCorners(5);
	curvyCorners(settings, document.getElementById('whatever'));
}

function configureRoundCorners(size){
	var settings = {
		tl: { radius: size },
		tr: { radius: size },
		bl: { radius: size },
		br: { radius: size },
		antiAlias: true
	}
	return settings;
}

function voteYes(){
	document.body.style.cursor = 'wait';
	$.post('/reorg/vote', {person: js_person_id, option: js_option_id, value: 1});
	newRumor();
}
function voteNo(){
	document.body.style.cursor = 'wait';
	$.post('/reorg/vote', {person: js_person_id, option: js_option_id, value: 0});
	newRumor();
}
function top10_voted(){ display_top10('/reorg/topvoted'); }
function top10_true(){ display_top10('/reorg/topvotedtrue'); }
function display_top10(url){
	if( $('#top10').is(':visible') ){
		$('#top10').fadeOut("slow");
		return;
	}
	$('.top10_item').remove();
	$.getJSON(""+url, function(data){
			$.each(data, function(index,entry){
					var yes = entry.votes[0];
					var no = entry.votes[1];
					var percent = (yes+no >= 1) ? (yes/(yes+no))*100 : 0;
					$('#top10').append('<div class="top10_item">'+entry.person+' '+entry.option+'</div>'+
							   '<div class="top10_item desc">'+percent.toFixed(0)+'%, '+(yes+no)+' votes</div>');
				});
			$('#top10').fadeIn();
		});
}

function initListeners(){
	$('#yes').bind({
			click: voteYes,
			mouseenter: function(){ document.body.style.cursor = 'pointer'; $('#yes').css('color', '#fff'); },
			mouseleave: function(){ document.body.style.cursor = 'default'; $('#yes').css('color', '#D9D7D0'); }
		});
	$('#no').bind({
			click: voteNo,
			mouseenter: function(){ document.body.style.cursor = 'pointer'; $('#no').css('color', '#fff'); },
			mouseleave: function(){ document.body.style.cursor = 'default'; $('#no').css('color', '#D9D7D0'); }
		});
	$('#whatever').bind({
			click: newRumor,
			mouseenter: function(){ document.body.style.cursor = 'pointer'; $('#whatever').css('color', '#fff'); },
			mouseleave: function(){ document.body.style.cursor = 'default'; $('#whatever').css('color', '#D9D7D0'); }
		});
	$('#top10_votes').bind({
			click: top10_voted,
			mouseenter: function(){ document.body.style.cursor = 'pointer'; $('#top10_votes').css('color', '#fff'); },
			mouseleave: function(){ document.body.style.cursor = 'default'; $('#top10_votes').css('color', '#D9D7D0'); }
		});
	$('#top10_true').bind({
			click: top10_true,
			mouseenter: function(){ document.body.style.cursor = 'pointer'; $('#top10_true').css('color', '#fff'); },
			mouseleave: function(){ document.body.style.cursor = 'default'; $('#top10_true').css('color', '#D9D7D0'); }
		});
}

function newRumor(){
	document.body.style.cursor = 'default';
	$('.c').remove();
	// Get the information
	$.getJSON('/reorg/random', function(data){
			js_person_id = data.person_id;
			js_person_name = data.person_name;
			js_option_id = data.option_id;
			js_option_label = data.option_label;
			js_yes = parseInt(data.yes, 10);
			js_nos = parseInt(data.no, 10);
			js_comments = data.comments;
			var votes = js_yes + js_nos;
			// And display it
			$('#person').html(js_person_name);
			$('#rumor').html(js_option_label);
			var percent = (votes >= 1) ? (js_yes/votes)*100 : 0;
			$('#opinion').html('Crédibilité : '+percent.toFixed(0)+'% ('+votes+' votes)');
			if(js_comments.length > 0){
				$('#placeholder').hide();
				$.each(js_comments, function(index, value){
						$('#comments').append('<div class="comment c">'+value+'</div>');
						if( 1+index < js_comments.length) $('#comments').append('<hr class="c"/>');
					});
			}
			else
				$('#placeholder').show();
		});
	window.scrollTo(0,0);
}

