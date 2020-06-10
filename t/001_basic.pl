use strict;
use warnings;

use PostgresNode;
use TestLib;
use Test::More tests => 1;

my $node1 = get_new_node('n1');
$node1->init;
$node1->append_conf('shared_preload_libraries', "'postgres_fdw, gtables_fdw'");
$node1->start;

my $node2 = get_new_node('n2');
$node2->init;
$node2->start;

$node1->safe_psql('postgres', 'CREATE EXTENSION postgres_fdw');
$node1->safe_psql('postgres', 'CREATE EXTENSION gtables_fdw');

# Create FDW servers
my $port = "". $node2->port;
$node1->safe_psql('postgres',
	"CREATE SERVER remote FOREIGN DATA WRAPPER postgres_fdw OPTIONS (port '$port')");
$node1->safe_psql('postgres', "CREATE USER MAPPING FOR PUBLIC SERVER remote");

# Create global table at each node
$node1->safe_psql('postgres',
	"CREATE TABLE gt1 (id serial PRIMARY KEY, payload int)");
$node2->safe_psql('postgres',
	"CREATE TABLE gt1 (id serial PRIMARY KEY, payload int)");

$node1->safe_psql('postgres',
	"INSERT INTO gt.GlobalTables (tblname) VALUES (gt1)");
is (0, "Test");


