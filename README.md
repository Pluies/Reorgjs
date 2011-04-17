Reorgjs
=======

Reorgjs is a rumor generator written in jest during a socially complicated reorganisation at work.

It creates rumors by picking a name from the list of employees and adding a fact about that person (all names and rumors options are defined in the database). The user can then vote to agree or disagree with the rumor, which will prompt another randomly generated rumor.

A list of most voted rumors can be shown using the buttons on the top right corner of the page.


How it works
============

Front-end
---------

Reorgjs' front-end is pure Javascript, as its name hints.

It uses a RESTful web service to get rumors and send the votes to the back-end.

Back-end
--------

Reorgjs' backend is a Sinatra web server. Its two main duties are to serve the index (from an HAML template) and to answer POST and GET requests emitted by the Javascript front-end.

The database (in which names, rumors and votes are stored) is SQLite.

I cannot include my version of this database because it includes my colleagues names, but here's the schema:

Air:Reorgjs florent$ echo .schema | sqlite3 reorgjs.sqlite
CREATE TABLE options(opt VARCHAR);
CREATE TABLE persons(name VARCHAR);
CREATE TABLE votes(person INT, option INT, value INT);

