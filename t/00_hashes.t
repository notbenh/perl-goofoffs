#!/usr/bin/env perl 
use strict;
use warnings;

use Test::Most qw{no_plan};

ok my %hash = ( key1 => 'value1'
              , key2 => 'value2'
              )
 , q{we can make a hash};

#-------------------------------------------------------------------------------
#  Basics
#-------------------------------------------------------------------------------
is $hash{key1}, 'value1', q{access a value by key, notice that we change the sigil as we are technicaly accessing a scalar};

is_deeply [sort keys %hash] # NOTE key's are not stored in order thus we need to use sort to insert some consistancy.
        , [qw{key1 key2}]
        , q{just the keys};

TODO: { local $TODO = q{Perl hashes do not maintain order};
  eq_or_diff [keys %hash]
           , [qw{key1 key2}]
           , q{just to show that it's possible to get things back in weird orders};
}

is_deeply [sort values %hash] 
        , [qw{value1 value2}]
        , q{now just the values};

is scalar(keys %hash), 2 , q{just checking that there are only two keys};
ok $hash{key3} = 'value3', q{adding to a hash};
is $hash{key3} , 'value3', q{yup that worked};
is scalar(keys %hash), 3 , q{just checking that there are now three keys};
ok delete $hash{key3}    , q{now lets make that go away};
is $hash{key3}, undef    , q{check, has no value};
is scalar(keys %hash), 2 , q{just checking that there are only two keys, again};

#-------------------------------------------------------------------------------
#  Unique keys
#-------------------------------------------------------------------------------
is scalar(keys %hash), 2 , q{just checking that there are still only two keys};
ok %hash = ( key1 => 'value1'
           , key2 => 'value2'
           , key1 => 'new value' # NOTE reuse of key1
           )
 , q{let's rebuild the hash so we can show the unique key aspect of hashes};

is_deeply [sort keys %hash] # NOTE key's are not stored in order thus we need to use sort to insert some consistancy.
        , [qw{key1 key2}]
        , q{wait... what happened to that other value?}; 
is $hash{key1}, 'new value', q{when hashes are assigned like this (list context) they take the last value for a key};

#-------------------------------------------------------------------------------
#  speaking of list context... what do hashes look like in list context? 
#-------------------------------------------------------------------------------
ok my ($k,$v) = %hash, q{what will this do?};
ok $k =~ m/^key/     , q{in list context we unroll the hash back to a list, effectivly.};

#-------------------------------------------------------------------------------
#  K, now that we know all that we can merging two or more 2D hashes... but only key => scalar value hashes
#  if you want to do a true merge of deeply nested hashes there are solutions on CPAN that do the right thing.
#-------------------------------------------------------------------------------
ok my %new_hash = ( key3 => 'value3' ), q{just a new hash to merge in to our %hash};
is $hash{key3}, undef                 , q{just making sure that there's not a key3 in %hash};
ok %hash  = (%hash, %new_hash)        , q{I wonder what we ended up with?};
is $hash{key3}, 'value3'              , q{cool a merged hash};

ok $new_hash{key1} = 'value from new hash', q{I wonder what happens when we have two hashes that share a key?};
ok $hash{key1} ne 'value from new hash'   , q{just checking that the value is not the new one, yet};
ok %hash = (%hash, %new_hash)             , q{lets merge new hash back in with the new duplicate key1};
is $hash{key1}, 'value from new hash'     , q{because new value1 was the last in the list it becomes the final value};

#===============================================================================
#  Leverage the attributes of a hash for other then storing data
#===============================================================================

my @data = qw{red red green red blue blue green blue red red gold blue red green green green gold};

#-------------------------------------------------------------------------------
#  extract how many like values there are in a list?
#-------------------------------------------------------------------------------
my %data_count = ();
$data_count{$_}++ for @data; 

is $data_count{red}  , 6, q{how many times did 'red' appear in @data?};
is $data_count{green}, 5, q{green?};
is $data_count{blue} , 4, q{blue?};
is $data_count{gold} , 2, q{gold?};

eq_or_diff [sort keys %data_count]
         , [qw{blue gold green red}]
         , q{if you just want the unique values, just pull the keys};


#===============================================================================
#  Now what about this reference idea?
#===============================================================================
sub hello {
  my $person = shift;
  return sprintf q{hello %s}, $person->{name}; # new syntax... we'll get to that
}

ok my %person = (name => 'ben'), q{hello me};
dies_ok {hello(%person)} q{because params are seen in list context, passing a hash like this is rarely what you want. This for example will die stateing that you can't use the scalar 'name' as a hash!};
ok my $ben = \%person  , q{So what we need to do is tell perl that we want to make a reference to the hash, this reference will be a scalar as it's just one point of data, that references the entire hash. Note that we tell perl to build a ref by preceeding with '\'.};
is hello($ben)         , 'hello ben', q{TADA! that worked};
is hello(\%person)     , 'hello ben', q{you can also do this in place};

is ref($ben)   , 'HASH'   , q{because refs look just like everything else, perl provides a way to check to see if and what kind of ref this is.};
my $scalar = 'string';
is ref($scalar), ''       , q{a scalar is not a reference to anything};

{ no strict;
  no warnings;
  # THIS BLOWS UP
  is $ben{name}, undef , q{this is not how you access the data of a reference, this blows up because perl is looking for %ben's name key rather then %person};
}
is $ben->{name}, 'ben' , q{see now that arrow syntax we used in our hello function makes sence};

# apart from the \% syntax there is another way to make a hash ref:
ok my $hashref = {braces => 'hashref'}, q{lets make a reference to an anonymous hash};
is $hashref->{braces}, 'hashref' , q{see works just like the other hashref};

dies_ok( sub{ keys $hashref; }, q{even though this is a ref to a hash, keys expects a hash (and dies when not given one). This has been changed in more recent versions of perl so if this test fails then it's likely that you're on a more recent version of perl.} );
ok keys %$hashref , q{so we need to tell perl to use the underlying hash, not the reference by giving it the '%' sign, this is called dereferencing };



#-------------------------------------------------------------------------------
#  Now that you understand refs, you can now make n-deep data structs
#-------------------------------------------------------------------------------
# what we have here is an arrayref of two people, each person is a hashref, then for the key pets we have another arrayref of hashrefs
my $folks = [ { name => 'ben'
              , pets => [ { name => 'trek'
                          , type => 'dog'
                          }
                        , { name => 'nia'
                          , type => 'cat'
                          } 
                        ]
              }
            , { name => 'stacey'
              , pets => [ { name => 'paige'
                          , type => 'dog'
                          }
                        , { name => 'thumper'
                          , type => 'cat'
                          }
                        , { name => 'billy'
                          , type => 'cat'
                          }
                        ]
              }
            ];

my @cat_names;
foreach my $person (@$folks) { #deref the outer array to get at each person hashref
  foreach my $pet  (@{$person->{pets}} ) {  # NOTE the use of {} is not to make a hashref rather to tell perl that we want to deref the value of $person->{pets} as an array
    push @cat_names, $pet->{name} if $pet->{type} eq 'cat';
  }
}

eq_or_diff \@cat_names, [qw{nia thumper billy}], q{there we go just the cat's names};

# another way to do the same type of thing (that you'll see me do a lot) so just wanted to show it to you

my @dog_names = map{ $_->{name}                    # 3: return just there names
                   } grep{ $_->{type} eq 'dog'     # 2: keep only the dogs
                         } map { @{ $_->{pets} }   # 1: for all the pets for this folk
                               } @$folks ;         # 0: for all the folks
                
eq_or_diff \@dog_names, [qw{trek paige}], q{same result, just the pups};


