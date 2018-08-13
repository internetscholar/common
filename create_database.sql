create table error
(
	id serial not null
		constraint error_pkey
			primary key,
	current_record jsonb,
	error text,
	time_error timestamp default now(),
	module text,
	ip text
)
;

create table aws_ami
(
  ami_name      text not null
    constraint aws_ami_pkey
    primary key,
  ami_id        text,
  key_pair_name text
);

create table aws_credentials
(
  aws_access_key_id     text not null
    constraint aws_credentials_pkey
    primary key,
  aws_secret_access_key text,
  region_name           text
);

create table google_search
(
	query_alias text not null
		constraint google_search_pkey
			primary key,
	query text,
	initial_date date,
	final_date date,
	google_domain text default 'www.google.com'::text,
	language_results text,
	country_results text,
	language_interface text,
	geo_tci text,
	geo_uule text,
	sort_by_date boolean default false,
	created_at timestamp default now()
)
;

create table google_subquery
(
	query_alias text not null
		constraint fk_google_search
			references google_search
				on update cascade on delete cascade,
	query_date date not null,
	query_url text,
	number_of_pages integer,
	created_at timestamp default now(),
	success boolean,
	id serial not null
		constraint google_subquery_pk
			primary key,
	ip text
)
;

create table google_result
(
	id serial not null
		constraint google_result_pkey
			primary key,
	query_alias text,
	query_date date,
	current_page integer,
	last_page integer,
	url text,
	title text,
	rank integer,
	date date,
	blurb_text text,
	blurb_html text,
	missing text
)
;
