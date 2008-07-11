CREATE TABLE `client_data_pairs` (
  `id` int(11) NOT NULL auto_increment,
  `key` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  `client_data_set_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `client_data_sets` (
  `id` int(11) NOT NULL auto_increment,
  `client_id` varchar(255) default NULL,
  `person_id` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `clients` (
  `id` varchar(255) NOT NULL default '',
  `name` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `encrypted_password` varchar(255) default NULL,
  `salt` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `collection_metadata_pairs` (
  `id` int(11) NOT NULL auto_increment,
  `key` varchar(255) default NULL,
  `value` varchar(255) default NULL,
  `collection_id` varchar(255) default NULL,
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
  `title` varchar(255) default NULL,
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

CREATE TABLE `images` (
  `id` int(11) NOT NULL auto_increment,
  `content_type` varchar(255) default NULL,
  `filename` varchar(255) default NULL,
  `data` longblob,
  `thumbnail` mediumblob,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `locations` (
  `id` int(11) NOT NULL auto_increment,
  `person_id` varchar(255) default NULL,
  `latitude` float default NULL,
  `longitude` float default NULL,
  `altitude` float default NULL,
  `vertical_accuracy` float default NULL,
  `horizontal_accuracy` float default NULL,
  `label` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `names` (
  `id` int(11) NOT NULL auto_increment,
  `given_name` varchar(255) default NULL,
  `family_name` varchar(255) default NULL,
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
  `encrypted_password` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `email` varchar(255) default NULL,
  `salt` varchar(255) default NULL,
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

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `person_id` varchar(255) default NULL,
  `ip_address` varchar(255) default NULL,
  `path` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `client_id` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `text_items` (
  `id` int(11) NOT NULL auto_increment,
  `text` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO schema_migrations (version) VALUES ('20080616073330');

INSERT INTO schema_migrations (version) VALUES ('20080616101055');

INSERT INTO schema_migrations (version) VALUES ('20080616120429');

INSERT INTO schema_migrations (version) VALUES ('20080617073013');

INSERT INTO schema_migrations (version) VALUES ('20080617073028');

INSERT INTO schema_migrations (version) VALUES ('20080617073034');

INSERT INTO schema_migrations (version) VALUES ('20080617103442');

INSERT INTO schema_migrations (version) VALUES ('20080617122819');

INSERT INTO schema_migrations (version) VALUES ('20080618102839');

INSERT INTO schema_migrations (version) VALUES ('20080619071224');

INSERT INTO schema_migrations (version) VALUES ('20080619105030');

INSERT INTO schema_migrations (version) VALUES ('20080623102903');

INSERT INTO schema_migrations (version) VALUES ('20080623110210');

INSERT INTO schema_migrations (version) VALUES ('20080623120054');

INSERT INTO schema_migrations (version) VALUES ('20080623140336');

INSERT INTO schema_migrations (version) VALUES ('20080623141403');

INSERT INTO schema_migrations (version) VALUES ('20080624113429');

INSERT INTO schema_migrations (version) VALUES ('20080627080113');

INSERT INTO schema_migrations (version) VALUES ('20080627080339');

INSERT INTO schema_migrations (version) VALUES ('20080627094307');

INSERT INTO schema_migrations (version) VALUES ('20080627095305');

INSERT INTO schema_migrations (version) VALUES ('20080627115227');

INSERT INTO schema_migrations (version) VALUES ('20080630052354');

INSERT INTO schema_migrations (version) VALUES ('20080702095516');

INSERT INTO schema_migrations (version) VALUES ('20080702095636');

INSERT INTO schema_migrations (version) VALUES ('20080702130342');

INSERT INTO schema_migrations (version) VALUES ('20080703053432');

INSERT INTO schema_migrations (version) VALUES ('20080703053611');

INSERT INTO schema_migrations (version) VALUES ('20080708122536');

INSERT INTO schema_migrations (version) VALUES ('20080709123150');