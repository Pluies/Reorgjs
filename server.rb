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
		dbquery('SELECT name
			 FROM persons
			 WHERE rowid=?', id).first.first
	end
	def option id
		dbquery('SELECT opt
			 FROM options
			 WHERE rowid=?', id).first.first
	end
	def random_person
		dbquery('SELECT rowid
			 FROM persons
			 WHERE rowid>=(abs(random()) % (SELECT 1+COUNT(name) FROM persons))
			 LIMIT 1').first.first
	end
	def random_option
		dbquery('SELECT rowid
			 FROM options
			 WHERE rowid>=(abs(random()) % (SELECT 1+COUNT(opt) FROM options))
			 LIMIT 1').first.first
	end
	def get_vote_for(person, option)
		yes, no = 0, 0
		no = dbquery('SELECT COUNT(*)
			      FROM votes
			      WHERE person=? AND option=? AND value=0', [person, option]).first.first
		yes = dbquery('SELECT COUNT(*)
			       FROM votes
			       WHERE person=? AND option=? AND value=1', [person, option]).first.first
		return [yes, no]
	end
	def add_vote_for(person, option, value)
		dbquery 'INSERT INTO votes(person, option, value) VALUES(?, ?, ?)', [person, option, value]
	end
	def top10_votes_true
		votes = {}
		dbquery('SELECT name, opt, value
			 FROM votes, persons, options
			 WHERE person = persons.rowid AND option=options.rowid
			 ORDER BY person').each do |row|
			# We are creating a hash who maps a rumor to its credibility.
			# The rumor is (an array) defined by the person and the option:
			hashkey = [row[0], row[1]]
			# And its credibility is a two-elements array [yes, no]
			votes[hashkey] ||= [0,0]
			votes[hashkey][row[2].to_i] += 1
		end
		weighed_votes = votes.dup
		weighed_votes.merge!(votes){ |k,v| # merge() is used as sort of map() over a hash
			# Behold the awe-inspiring ranking algorithm!
			(v[1]**1.8) / (v[0]+1)
		}
		top10 = []
		until top10.length == 10 or weighed_votes.empty?
			max = weighed_votes.index(weighed_votes.values.max)
			top10 << { :person => max[0],
				   :option => max[1],
				   :votes => votes[max].reverse
				   # reverse: because JS expects [yes,no] whilst we populated the array with [0] as noes and [1] as yeses
			}
			weighed_votes.delete max
		end
		return top10
	end
	def top10_most_votes
		top10 = []
		dbquery('SELECT person, name, option, opt, COUNT(value) AS total
			 FROM votes, persons, options
			 WHERE person = persons.rowid AND option=options.rowid
			 GROUP BY person, option
			 ORDER BY total DESC
			 LIMIT 10').each do |row|
			person_id, option_id = row[0], row[2]
			top10 << { :person => row[1],
				   :option => row[3],
				   :votes => (get_vote_for person_id, option_id)}
		end
		return top10
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
	JSON	top10_most_votes
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


