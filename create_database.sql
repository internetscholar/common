create table error
(
	id serial not null
		constraint error_primary_key
			primary key,
	current_record jsonb,
	error text,
	time_error timestamp with time zone default now(),
	module text,
	ip text
);

create table aws_ami
(
  region_name    text not null,
  ami_name      text not null,
  ami_id        text,
  key_pair_name text,
  constraint aws_ami_primary_key
    primary key (region_name, ami_name)
);

create table aws_credentials
(
  account               text,
  aws_access_key_id     text not null
    constraint aws_credentials_primary_key
    primary key,
  aws_secret_access_key text,
	created_at timestamp with time zone default now()
);

create table project
(
	project_name text not null constraint project_primary_key primary key,
	active boolean default TRUE,
	aws_region text,
	created_at timestamp with time zone default now()
);

create table google_search_query
(
	query_alias text not null
		constraint google_search_primary_key
			primary key,
	search_terms text,
	initial_date date,
	final_date date,
	google_domain text default 'www.google.com'::text,
	language_results text,
	country_results text,
	language_interface text,
	geo_tci text,
	geo_uule text,
	sort_by_date boolean default false,
	created_at timestamp with time zone default now(),
  project_name text not null
    constraint fk_project_google
      references project
        on update cascade on delete cascade
);

create table google_search_subquery
(
	query_alias text not null,
	query_date date not null,
	query_url text,
	created_at timestamp with time zone default now(),
  constraint google_search_subquery_pk
    primary key(query_alias, query_date),
	constraint fk_google_search_query
    foreign key (query_alias)
  		references google_search_query (query_alias)
	  		on update cascade on delete cascade
);

create table google_search_attempt
(
  query_alias text not null,
  query_date date not null,
	created_at timestamp with time zone default now(),
	success boolean,
	ip text,
  constraint fk_google_search_attempt
    foreign key (query_alias, query_date)
      references google_search_subquery (query_alias, query_date)
        on update cascade on delete cascade,
  constraint google_search_attempt_pk
    primary key(query_alias, query_date, created_at)
);

create table google_search_result
(
	result_id serial not null
		constraint google_result_primary_key
			primary key,
	query_alias text,
	query_date date,
	page_number integer,
	url text,
	title text,
	rank integer,
	date date,
	blurb_text text,
	blurb_html text,
	missing text,
  result_type text,
  constraint fk_google_search_result
    foreign key (query_alias, query_date)
      references google_search_subquery (query_alias, query_date)
        on update cascade on delete cascade
);


create table twitter_scraping_query
(
  query_alias          text not null
    constraint twitter_scraping_query_primary_key
    primary key,
  search_terms         text,
  since                timestamp(0) with time zone not null,
  until                timestamp(0) with time zone not null,
  language             text,
  tolerance_in_seconds interval(0) not null default '01:00:00'::interval,
  subquery_interval_in_seconds interval(0) not null default '1 day'::interval,
	created_at timestamp with time zone default now(),
  project_name text not null
    constraint fk_project_twitter
      references project
        on update cascade on delete cascade
);


create table twitter_scraping_subquery
(
  query_alias text not null,
  since       timestamp(0) with time zone not null,
  complete    boolean default FALSE ,
	created_at timestamp with time zone default now(),
  constraint fk_twitter_scraping_subquery
    foreign key (query_alias)
      references twitter_scraping_query(query_alias)
        on update cascade on delete cascade,
  constraint pk_twitter_scraping_subquery primary key (query_alias, since)
);


create table twitter_scraping_attempt
(
  query_alias text not null,
  since       timestamp(0) with time zone not null,
  until       timestamp(0) with time zone not null,
  twitter_url text,
  ip text,
  empty boolean default false,
	created_at timestamp with time zone default now(),
  constraint fk_twitter_scraping_attempt
    foreign key (query_alias, since)
      references twitter_scraping_subquery(query_alias, since)
        on update cascade on delete cascade,
  constraint pk_twitter_scraping_attempt primary key (query_alias, since, until)
);


create table twitter_dry_tweet
(
  query_alias text not null,
  since       timestamp(0) with time zone not null,
  until       timestamp(0) with time zone not null,
  tweet_id    bigint not null,
	published_at timestamp(0) with time zone not null,
  constraint fk_twitter_dry_tweet
    foreign key (query_alias, since, until)
      references twitter_scraping_attempt(query_alias, since, until)
        on update cascade on delete cascade,
  constraint pk_twitter_dry_tweet primary key (query_alias, since, tweet_id)
);

create table twitter_hydration_request
(
	request_id serial not null
		constraint twitter_hydration_request_primary_key
			primary key,
  ip text,
	created_at timestamp with time zone default now()
);

create table twitter_hydrated_tweet
(
  tweet_id bigint not null,
  response jsonb,
  project_name text not null
    constraint fk_project_hydrated_tweet
      references project
        on update cascade on delete cascade,
  request_id integer
    constraint fk_request_hydrated_tweet
      references twitter_hydration_request (request_id)
        on update cascade on delete cascade,
  constraint pk_twitter_hydrated_tweet primary key (project_name, tweet_id)
);


create table url_http_status
(
  status_code integer not null primary key,
  message text,
  description text
);

insert into url_http_status (status_code, message, description) values
(100, 'Continue', 'The server has received the request headers and the client should proceed to send the request body (in the case of a request for which a body needs to be sent; for example, a POST request). Sending a large request body to a server after a request has been rejected for inappropriate headers would be inefficient. To have a server check the request''s headers, a client must send Expect: 100-continue as a header in its initial request and receive a 100 Continue status code in response before sending the body. If the client receives an error code such as 403 (Forbidden) or 405 (Method Not Allowed) then it should not send the request''s body. The response 417 Expectation Failed indicates that the request should be repeated without the Expect header as it indicates that the server does not support expectations (this is the case, for example, of HTTP/1.0 servers).'),
(101, 'Switching Protocols', 'The requester has asked the server to switch protocols and the server has agreed to do so.'),
(102, 'Processing (WebDAV; RFC 2518)', 'A WebDAV request may contain many sub-requests involving file operations, requiring a long time to complete the request. This code indicates that the server has received and is processing the request, but no response is available yet. This prevents the client from timing out and assuming the request was lost.'),
(103, 'Early Hints (RFC 8297)', 'Used to return some response headers before final HTTP message.'),
(200, 'OK', 'Standard response for successful HTTP requests. The actual response will depend on the request method used. In a GET request, the response will contain an entity corresponding to the requested resource. In a POST request, the response will contain an entity describing or containing the result of the action.'),
(201, 'Created', 'The request has been fulfilled, resulting in the creation of a new resource.'),
(202, 'Accepted', 'The request has been accepted for processing, but the processing has not been completed. The request might or might not be eventually acted upon, and may be disallowed when processing occurs.'),
(203, 'Non-Authoritative Information (since HTTP/1.1)', 'The server is a transforming proxy (e.g. a Web accelerator) that received a 200 OK from its origin, but is returning a modified version of the origin''s response.'),
(204, 'No Content', 'The server successfully processed the request and is not returning any content.'),
(205, 'Reset Content', 'The server successfully processed the request, but is not returning any content. Unlike a 204 response, this response requires that the requester reset the document view.'),
(206, 'Partial Content (RFC 7233)', 'The server is delivering only part of the resource (byte serving) due to a range header sent by the client. The range header is used by HTTP clients to enable resuming of interrupted downloads, or split a download into multiple simultaneous streams.'),
(207, 'Multi-Status (WebDAV; RFC 4918)', 'The message body that follows is by default an XML message and can contain a number of separate response codes, depending on how many sub-requests were made.'),
(208, 'Already Reported (WebDAV; RFC 5842)', 'The members of a DAV binding have already been enumerated in a preceding part of the (multi-status) response, and are not being included again.'),
(226, 'IM Used (RFC 3229)', 'The server has fulfilled a request for the resource, and the response is a representation of the result of one or more instance-manipulations applied to the current instance.'),
(300, 'Multiple Choices', 'Indicates multiple options for the resource from which the client may choose (via agent-driven content negotiation). For example, this code could be used to present multiple video format options, to list files with different filename extensions, or to suggest word-sense disambiguation.'),
(301, 'Moved Permanently', 'This and all future requests should be directed to the given URI.'),
(302, 'Found (Previously "Moved temporarily")', 'Tells the client to look at (browse to) another url. 302 has been superseded by 303 and 307. This is an example of industry practice contradicting the standard. The HTTP/1.0 specification (RFC 1945) required the client to perform a temporary redirect (the original describing phrase was "Moved Temporarily"), but popular browsers implemented 302 with the functionality of a 303 See Other. Therefore, HTTP/1.1 added status codes 303 and 307 to distinguish between the two behaviours. However, some Web applications and frameworks use the 302 status code as if it were the 303.'),
(303, 'See Other (since HTTP/1.1)', 'The response to the request can be found under another URI using the GET method. When received in response to a POST (or PUT/DELETE), the client should presume that the server has received the data and should issue a new GET request to the given URI.'),
(304, 'Not Modified (RFC 7232)', 'Indicates that the resource has not been modified since the version specified by the request headers If-Modified-Since or If-None-Match. In such case, there is no need to retransmit the resource since the client still has a previously-downloaded copy.'),
(305, 'Use Proxy (since HTTP/1.1)', 'The requested resource is available only through a proxy, the address for which is provided in the response. Many HTTP clients (such as Mozilla and Internet Explorer) do not correctly handle responses with this status code, primarily for security reasons.'),
(306, 'Switch Proxy', 'No longer used. Originally meant "Subsequent requests should use the specified proxy."'),
(307, 'Temporary Redirect (since HTTP/1.1)', 'In this case, the request should be repeated with another URI; however, future requests should still use the original URI. In contrast to how 302 was historically implemented, the request method is not allowed to be changed when reissuing the original request. For example, a POST request should be repeated using another POST request.'),
(308, 'Permanent Redirect (RFC 7538)', 'The request and all future requests should be repeated using another URI. 307 and 308 parallel the behaviors of 302 and 301, but do not allow the HTTP method to change. So, for example, submitting a form to a permanently redirected resource may continue smoothly.'),
(400, 'Bad Request', 'The server cannot or will not process the request due to an apparent client error (e.g., malformed request syntax, size too large, invalid request message framing, or deceptive request routing).'),
(401, 'Unauthorized (RFC 7235)', 'Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided. The response must include a WWW-Authenticate header field containing a challenge applicable to the requested resource. See Basic access authentication and Digest access authentication. 401 semantically means "unauthenticated", i.e. the user does not have the necessary credentials. Note: Some sites issue HTTP 401 when an IP address is banned from the website (usually the website domain) and that specific address is refused permission to access a website.'),
(402, 'Payment Required', 'Reserved for future use. The original intention was that this code might be used as part of some form of digital cash or micro payment scheme, as proposed for example by GNU Taler, but that has not yet happened, and this code is not usually used. Google Developers API uses this status if a particular developer has exceeded the daily limit on requests. Sipgate uses this code if an account does not have sufficient funds to start a call. Shopify uses this code when the store has not paid their fees and is temporarily disabled. '),
(403, 'Forbidden', 'The request was valid, but the server is refusing action. The user might not have the necessary permissions for a resource, or may need an account of some sort.'),
(404, 'Not Found', 'The requested resource could not be found but may be available in the future. Subsequent requests by the client are permissible.'),
(405, 'Method Not Allowed', 'A request method is not supported for the requested resource; for example, a GET request on a form that requires data to be presented via POST, or a PUT request on a read-only resource.'),
(406, 'Not Acceptable', 'The requested resource is capable of generating only content not acceptable according to the Accept headers sent in the request. See Content negotiation.'),
(407, 'Proxy Authentication Required (RFC 7235)', 'The client must first authenticate itself with the proxy.'),
(408, 'Request Timeout', 'The server timed out waiting for the request. According to HTTP specifications: "The client did not produce a request within the time that the server was prepared to wait. The client MAY repeat the request without modifications at any later time."'),
(409, 'Conflict', 'Indicates that the request could not be processed because of conflict in the current state of the resource, such as an edit conflict between multiple simultaneous updates.'),
(410, 'Gone', 'Indicates that the resource requested is no longer available and will not be available again. This should be used when a resource has been intentionally removed and the resource should be purged. Upon receiving a 410 status code, the client should not request the resource in the future. Clients such as search engines should remove the resource from their indices. Most use cases do not require clients and search engines to purge the resource, and a "404 Not Found" may be used instead.'),
(411, 'Length Required', 'The request did not specify the length of its content, which is required by the requested resource.'),
(412, 'Precondition Failed (RFC 7232)', 'The server does not meet one of the preconditions that the requester put on the request.'),
(413, 'Payload Too Large (RFC 7231)', 'The request is larger than the server is willing or able to process. Previously called "Request Entity Too Large".'),
(414, 'URI Too Long (RFC 7231)', 'The URI provided was too long for the server to process. Often the result of too much data being encoded as a query-string of a GET request, in which case it should be converted to a POST request. Called "Request-URI Too Long" previously.'),
(415, 'Unsupported Media Type', 'The request entity has a media type which the server or resource does not support. For example, the client uploads an image as image/svg+xml, but the server requires that images use a different format.'),
(416, 'Range Not Satisfiable (RFC 7233)', 'The client has asked for a portion of the file (byte serving), but the server cannot supply that portion. For example, if the client asked for a part of the file that lies beyond the end of the file. Called "Requested Range Not Satisfiable" previously.'),
(417, 'Expectation Failed', 'The server cannot meet the requirements of the Expect request-header field.'),
(418, 'I''m a teapot (RFC 2324, RFC 7168)', 'This code was defined in 1998 as one of the traditional IETF April Fools'' jokes, in RFC 2324, Hyper Text Coffee Pot Control Protocol, and is not expected to be implemented by actual HTTP servers. The RFC specifies this code should be returned by teapots requested to brew coffee. This HTTP status is used as an Easter egg in some websites, including Google.com.'),
(421, 'Misdirected Request (RFC 7540)', 'The request was directed at a server that is not able to produce a response (for example because of connection reuse).'),
(422, 'Un-processable Entity (WebDAV; RFC 4918)', 'The request was well-formed but was unable to be followed due to semantic errors.'),
(423, 'Locked (WebDAV; RFC 4918)', 'The resource that is being accessed is locked.'),
(424, 'Failed Dependency (WebDAV; RFC 4918)', 'The request failed because it depended on another request and that request failed (e.g., a PROPPATCH).'),
(426, 'Upgrade Required', 'The client should switch to a different protocol such as TLS/1.0, given in the Upgrade header field.'),
(428, 'Precondition Required (RFC 6585)', 'The origin server requires the request to be conditional. Intended to prevent the ''lost update'' problem, where a client GETs a resource''s state, modifies it, and PUTs it back to the server, when meanwhile a third party has modified the state on the server, leading to a conflict."'),
(429, 'Too Many Requests (RFC 6585)', 'The user has sent too many requests in a given amount of time. Intended for use with rate-limiting schemes.'),
(431, 'Request Header Fields Too Large (RFC 6585)', 'The server is unwilling to process the request because either an individual header field, or all the header fields collectively, are too large.'),
(451, 'Unavailable For Legal Reasons (RFC 7725)', 'A server operator has received a legal demand to deny access to a resource or to a set of resources that includes the requested resource. The code 451 was chosen as a reference to the novel Fahrenheit 451 (see the Acknowledgements in the RFC).'),
(500, 'Internal Server Error', 'A generic error message, given when an unexpected condition was encountered and no more specific message is suitable.'),
(501, 'Not Implemented', 'The server either does not recognize the request method, or it lacks the ability to fulfil the request. Usually this implies future availability (e.g., a new feature of a web-service API).'),
(502, 'Bad Gateway', 'The server was acting as a gateway or proxy and received an invalid response from the upstream server.'),
(503, 'Service Unavailable', 'The server is currently unavailable (because it is overloaded or down for maintenance). Generally, this is a temporary state.'),
(504, 'Gateway Timeout', 'The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.'),
(505, 'HTTP Version Not Supported', 'The server does not support the HTTP protocol version used in the request.'),
(506, 'Variant Also Negotiates (RFC 2295)', 'Transparent content negotiation for the request results in a circular reference.'),
(507, 'Insufficient Storage (WebDAV; RFC 4918)', 'The server is unable to store the representation needed to complete the request.'),
(508, 'Loop Detected (WebDAV; RFC 5842)', 'The server detected an infinite loop while processing the request (sent in lieu of 208 Already Reported).'),
(510, 'Not Extended (RFC 2774)', 'Further extensions to the request are required for the server to fulfill it.'),
(511, 'Network Authentication Required (RFC 6585)', 'The client needs to authenticate to gain network access. Intended for use by intercepting proxies used to control access to the network (e.g., "captive portals" used to require agreement to Terms of Service before granting full Internet access via a Wi-Fi hot-spot).'),
(218, 'This is fine (Apache Web Server)', 'Used as a catch-all error condition for allowing response bodies to flow through Apache when ProxyErrorOverride is enabled. When ProxyErrorOverride is enabled in Apache, response bodies that contain a status code of 4xx or 5xx are automatically discarded by Apache in favor of a generic response or a custom response specified by the ErrorDocument directive.'),
(420, 'Enhance Your Calm (Twitter)', 'Returned by version 1 of the Twitter Search and Trends API when the client is being rate limited; versions 1.1 and later use the 429 Too Many Requests response code instead.'),
(450, 'Blocked by Windows Parental Controls (Microsoft)', 'The Microsoft extension code indicated when Windows Parental Controls are turned on and are blocking access to the requested web page.'),
(498, 'Invalid Token (Esri)', 'Returned by ArcGIS for Server. Code 498 indicates an expired or otherwise invalid token.'),
(499, 'Token Required (Esri)', 'Returned by ArcGIS for Server. Code 499 indicates that a token is required but was not submitted.'),
(509, 'Bandwidth Limit Exceeded (Apache Web Server/cPanel)', 'The server has exceeded the bandwidth specified by the server administrator; this is often used by shared hosting providers to limit the bandwidth of customers.'),
(530, 'Site is frozen', 'Used by the Pantheon web platform to indicate a site that has been frozen due to inactivity.'),
(598, '(Informal convention) Network read timeout error', 'Used by some HTTP proxies to signal a network read timeout behind the proxy to a client in front of the proxy.'),
(440, 'Login Time-out', 'The client''s session has expired and must log in again.'),
(449, 'Retry With', 'The server cannot honour the request because the user has not provided the required information.'),
(444, 'No Response', 'Used internally to instruct the server to return no information to the client and close the connection immediately.'),
(494, 'Request header too large', 'Client sent too large request or too long header line.'),
(495, 'SSL Certificate Error', 'An expansion of the 400 Bad Request response code, used when the client has provided an invalid client certificate.'),
(496, 'SSL Certificate Required', 'An expansion of the 400 Bad Request response code, used when a client certificate is required but not provided.'),
(497, 'HTTP Request Sent to HTTPS Port', 'An expansion of the 400 Bad Request response code, used when the client has made a HTTP request to a port listening for HTTPS requests.'),
(520, 'Unknown Error', 'The 520 error is used as a "catch-all response for when the origin server returns something unexpected", listing connection resets, large headers, and empty or invalid responses as common triggers.'),
(521, 'Web Server Is Down', 'The origin server has refused the connection from Cloudflare.'),
(522, 'Connection Timed Out', 'Cloudflare could not negotiate a TCP handshake with the origin server.'),
(523, 'Origin Is Unreachable', 'Cloudflare could not reach the origin server; for example, if the DNS records for the origin server are incorrect.'),
(524, 'A Timeout Occurred', 'Cloudflare was able to complete a TCP connection to the origin server, but did not receive a timely HTTP response.'),
(525, 'SSL Handshake Failed', 'Cloudflare could not negotiate a SSL/TLS handshake with the origin server.'),
(526, 'Invalid SSL Certificate', 'Cloudflare could not validate the SSL/TLS certificate that the origin server presented.'),
(527, 'Rail-gun Error', 'Error 527 indicates that the request timed out or failed after the WAN connection had been established.'),
(600, 'WebScholar: 1', 'Exception during URL validation'),
(601, 'WebScholar: 2', 'Schema is not HTTPS or HTTP'),
(999, 'Request denied', 'LinkedIn does not want to share data'),
(479, 'Unknown error', 'Unknown error'),
(596, 'Unknown error', 'Unknown error'),
(456, 'Unknown error', 'Unknown error'),
(210, 'Unknown error', 'Unknown error')
on conflict do nothing;

create table url
(
  url text not null,
  accessed_at timestamp with time zone default now(),
  next text null,
  final_url text not null,
  status_code integer not null
    constraint fk_url_status_code
      references url_http_status
        on update cascade on delete cascade,
  project_name text not null
    constraint fk_url_project
      references project
        on update cascade on delete cascade,
  constraint pk_url primary key (project_name, url),
  constraint fk_url_next foreign key (project_name, next)
      references url(project_name, url)
        on update cascade on delete cascade,
  constraint fk_url_final_url foreign key (project_name, final_url)
      references url(project_name, url)
        on update cascade on delete cascade
);


create table url_watson_nlp
(
  url text not null,
  created_at timestamp with time zone default now(),
  project_name text not null
    constraint fk_url_watson_nlp_project
      references project
        on update cascade on delete cascade,
  constraint pk_url_watson_nlp primary key (project_name, url),
  constraint fk_url_watson_nlp_url
    foreign key (project_name, url)
      references url(project_name, url)
        on update cascade on delete cascade
);


create table url_facebook_stats
(
  url text not null,
  created_at timestamp with time zone default now(),
  stats jsonb,
  og_object jsonb,
  project_name text not null
    constraint fk_url_facebook_stats_project
      references project
        on update cascade on delete cascade,
  constraint pk_url_facebook_stats primary key (project_name, url),
  constraint fk_url_facebook_stats_url
    foreign key (project_name, url)
      references url(project_name, url)
        on update cascade on delete cascade
);


create table twitter_credentials
(
  account             text,
  email               text,
  app_name            text,
  app_id              text not null
    constraint twitter_credentials_primary_key
    primary key,
  consumer_key        text,
  consumer_secret     text,
  access_token        text,
  access_token_secret text,
	created_at timestamp with time zone default now()
);

create table facebook_user_credentials
(
  email        text not null
    constraint facebook_user_credentials_primary_key
    primary key,
  access_token text,
	created_at timestamp with time zone default now()
);

create table facebook_app_credentials
(
  app_name   text not null
    constraint facebook_credentials_primary_key
    primary key,
  app_id     text,
  app_secret text,
	created_at timestamp with time zone default now()
);


create table watson_credentials
(
  url      text,
  username text not null,
  password text,
  email    text not null
    constraint watson_credentials_email_primary_key
    primary key,
	created_at timestamp with time zone default now()
);


create table yandex_email
(
  username         text not null,
  first_name       text,
  last_name        text,
  password_email   text,
  musician_surname text,
  created_at       timestamp with time zone default now(),
  email            text not null
    constraint yandex_email_primary_key
    primary key
);