- advanced airtable syncing
- raw airtable syncing for sanity
users schema:
id str
created_at stamp
projects string
orders Linked thing
slack id string
slack username string thing

shop order schema: 
name str
user_id (linked field)
id (user_id auto lookup ignore this db wise)
item id (linked field)


for shop items in the seed pull from airtable
each how pull from airtable to sync / update the shop :)

data for a funnel (?)

- sync to the ysws db and submit

api wise:
handle ysws db submission with hca token to autofill funny pii
block non idv verified people from doing it
for email signup just redirect to use hca :pf:


