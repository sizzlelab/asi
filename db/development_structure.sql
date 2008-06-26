CREATE TABLE `binary_items` (
  `id` int(11) NOT NULL auto_increment,
  `data` blob,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `content_type` varchar(255) default NULL,
  `filename` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clients` (
  `id` varchar(255) NOT NULL default '',
  `name` varchar(255) default NULL,
  `api_key` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `collections` (
  `id` varchar(255) NOT NULL default '',
  `read_only` tinyint(1) default NULL,
  `client_id` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `owner_id` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `connections` (
  `id` int(11) NOT NULL auto_increment,
  `person_id` varchar(255) default NULL,
  `contact_id` varchar(255) default NULL,
  `status` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `ownerships` (
  `id` int(11) NOT NULL auto_increment,
  `collection_id` varchar(255) default NULL,
  `item_id` varchar(255) default NULL,
  `item_type` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `people` (
  `id` varchar(255) NOT NULL default '',
  `username` varchar(255) default NULL,
  `password` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `email` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `person_names` (
  `id` int(11) NOT NULL auto_increment,
  `given_name` varchar(255) default '',
  `family_name` varchar(255) default '',
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `person_id` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `person_specs` (
  `id` int(11) NOT NULL auto_increment,
  `person_id` varchar(255) default NULL,
  `status_message` varchar(255) default '',
  `birthdate` date default NULL,
  `gender` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `text_items` (
  `id` int(11) NOT NULL auto_increment,
  `text` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20080616101055');

INSERT INTO schema_migrations (version) VALUES ('20080616120429');

INSERT INTO schema_migrations (version) VALUES ('20080617073013');

INSERT INTO schema_migrations (version) VALUES ('20080617073028');

INSERT INTO schema_migrations (version) VALUES ('20080617073034');

INSERT INTO schema_migrations (version) VALUES ('20080617103442');

INSERT INTO schema_migrations (version) VALUES ('20080617122819');

INSERT INTO schema_migrations (version) VALUES ('20080619071224');

INSERT INTO schema_migrations (version) VALUES ('20080619105030');

INSERT INTO schema_migrations (version) VALUES ('20080623102903');

INSERT INTO schema_migrations (version) VALUES ('20080623110210');

INSERT INTO schema_migrations (version) VALUES ('20080623120054');

INSERT INTO schema_migrations (version) VALUES ('20080623141403');

INSERT INTO schema_migrations (version) VALUES ('20080624113429');