require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'net/http'
require 'json/pure'

helpers do
	def dbquery(query, params=nil)
		retries = 5
		result = []
		db = SQLite3::Database.new "reorgjs.sqlite"
		begin
			if params
				db.execute(query, params) do |row|
					result << row
				end
			else
				db.execute(query) do |row|
					result << row
				end
			end
		rescue Exception
			# SQLite can only process one request at a time, and might
			# throw exception during standard activities (e.g. while 
			# fecthing a new rumor after a vote). This small-sleep-and-
			# retry strategy is kind of a kludge.
			sleep 0.1
			retry if (retries -= 1) > 0
		end
		return result
	end
	def person id
		dbquery('select name from persons where rowid=?', id).first.first
	end
	def option id
		dbquery('select opt from options where rowid=?', id).first.first
	end
	def random_person
		dbquery('select rowid from persons where rowid>=(abs(random()) % (select 1+count(name) from persons)) limit 1').first.first
	end
	def random_option
		dbquery('select rowid from options where rowid>=(abs(random()) % (select 1+count(opt) from options)) limit 1').first.first
	end
	def get_vote_for(person, option)
		yes, no = 0, 0
		no = dbquery('select count(*) from votes where person=? and option=? and value=0', [person, option]).first.first
		yes = dbquery('select count(*) from votes where person=? and option=? and value=1', [person, option]).first.first
		return [yes, no]
	end
	def add_vote_for(person, option, value)
		dbquery 'insert into votes(person, option, value) values(?, ?, ?)', [person, option, value]
	end
	def top10_votes
		top10 = []
		dbquery('SELECT person, name, option, opt, count(value) AS total FROM votes, persons, options WHERE person = persons.rowid AND option=options.rowid GROUP BY person, option ORDER BY total DESC LIMIT 10').each do |row|
				person_id, option_id = row[0], row[2]
				top10 << { :person => row[1],
					   :option => row[3],
					   :votes => (get_vote_for person_id, option_id)}
		end
		return top10
	end
	def top10_votes_true
		top10 = []
		dbquery('SELECT person, name, option, opt, count(value) AS total FROM votes, persons, options WHERE person = persons.rowid AND option=options.rowid GROUP BY person, option ORDER BY total DESC LIMIT 10').each do |row|
				person_id, option_id = row[0], row[2]
				top10 << { :person => row[1],
					   :option => row[3],
					   :votes => (get_vote_for person_id, option_id)}
		end
		return top10
	end
	def top10_comments

	end
end


## ------------- ##
## -- ReorgJS--- ##
## ------------- ##


get '/reorg' do
	if params[:lang] and params[:lang] == "en"
		haml :reorg_en
	else
		haml :reorg_fr
	end
end

get '/reorg/random' do
	content_type :json
	person_id = random_person
	option_id = random_option
	yes, no = get_vote_for person_id, option_id
	JSON    'person_id' => person_id,
		'person_name' => (person person_id),
		'option_id' => option_id,
		'option_label' => (option option_id),
		'yes' => yes,
		'no' => no
end

get '/reorg/topvoted' do
	content_type :json
	JSON	top10_votes
end

get '/reorg/topvotedtrue' do
	content_type :json
	JSON	top10_votes_true
end

post '/reorg/vote' do
	add_vote_for params[:person], params[:option], params[:value]
	200
end

get '/reorg/stylesheet.css' do
	content_type 'text/css', :charset => 'utf-8'
	sass :stylesheet
end


