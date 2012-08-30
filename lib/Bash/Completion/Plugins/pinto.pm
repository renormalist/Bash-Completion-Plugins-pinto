## no critic (RequireUseStrict)
package Bash::Completion::Plugins::pinto;
# ABSTRACT: Bash completion for pinto

## use critic (RequireUseStrict)
use strict;
use warnings;
use feature 'switch';
use parent 'Bash::Completion::Plugin';

use Bash::Completion::Utils qw(command_in_path);

my @pinto_commands = qw/commands help add copy
                           delete edit index init
                           install list manual merge
                           new nop pin props pull
                           stacks statistics unpin
                           verify version
                          /;

my @pinto_options = qw/-h --help
                       -r --root
                       -q --quiet
                       -v --verbose
                       --nocolor
                       /;

sub should_activate {
    return [ grep { command_in_path($_) } qw/pinto/ ];
}

sub _extract_stack {
    my ( $stack ) = @_;

    #$stack =~ s/\@.*//;
    return $stack;
}

sub _get_stacks {
    my @stacks = split /\n/, qx(pinto stacks);
    my ( $current_stack ) = grep { /^\*\s*/ } @stacks;
    ( $current_stack )    = $current_stack =~ /^\*\s*(\S+)/;

    $current_stack = _extract_stack($current_stack);

    return ( $current_stack, map { /^\*?\s*(?<name>\S+)/; $+{'name'} } @stacks );
}

sub complete {
    my ( $self, $r ) = @_;

    my $word = $r->word;

    if ($word =~ /^-/) {
            $r->candidates(grep { /^\Q$word\E/ } @pinto_options);
    } else {
            my @args = $r->args;

            my @orig_args = @args;

            shift @args; # get rid of 'pinto'

            # get rid of (-rFOO|-r FOO|--root FOO|--root=FOO)
            if ($args[0] =~ qr/^(?:-r|--root)$/) {
                    if ($args[0] =~ qr/^(?:--root=)$/) {
                            shift @args;
                    } elsif ($args[1]) {
                            shift @args;
                            shift @args;
                    }
            }

            shift @args until @args == 0 || $args[0] !~ /^-/;

            my $command = $args[0] // '';

            my @options = ();
            given($command) {
                    when ("add")        { @options = qw(--author --dryrun --norecurse --pin --stack); }
                    when ("copy")       { @options = qw(--description --dryrun); }
                    when ("edit")       { @options = qw(--default --dryrun --properties -P); }
                    when ("init")       { @options = qw(--source); }
                    when ("install")    { @options = qw(--cpanm-exe --cpanm
                                                        --cpanm-options -o
                                                        -l --local-lib --local-lib-contained
                                                        --pull
                                                        --stack
                                                      ); }
                    when ("list")       { @options = qw(--author -A
                                                        --distributions -D
                                                        --format
                                                        --packages -P
                                                        --pinned
                                                        --stack -s
                                                      ); }
                    when ("merge")      { @options = qw(--dryrun); }
                    when ("new")        { @options = qw(--dryrun --description); }
                    when ("nop")        { @options = qw(--sleep); }
                    when ("pin")        { @options = qw(--dryrun --stack); }
                    when ("props")      { @options = qw(--format); }
                    when ("pull")       { @options = qw(--dryrun --norecurse --stack); }
                    when ("stacks")     { @options = qw(--format); }
                    when ("unpin")      { @options = qw(--dryrun --stack); }
                    default { };
            }

            given($command) {
                    when($command eq $word) {
                            $r->candidates(grep { /^\Q$word\E/ }
                                           ( @pinto_commands, @pinto_options ));
                    }
                    ##_get_stacks() is quite slow for my demanding taste (due to slow pinto startup time)
                    when(qr/^(?:copy|delete|index|list|merge|pin|unpin)$/) {
                            my ( $current_stack, @stacks ) = _get_stacks();
                            $r->candidates(grep { /^\Q$word\E/ } ( @options, @stacks ));
                    }
                    when(qr/^(?:manual|help)$/) {
                            $r->candidates(grep { /^\Q$word\E/ }
                                           ( @pinto_commands ));
                    }
                    default {
                            # all other commands (including unrecognized ones) get
                            # no completions
                            $r->candidates(grep { /^\Q$word\E/ } ( @options ));
                    }
            }
    }
}

1;

__END__

=head1 DESCRIPTION

L<Bash::Completion> support for L<pinto|App::Pinto>.  Completes pinto
commands and options.

=head1 SEE ALSO

L<Bash::Completion>, L<Bash::Completion::Plugin>, L<App::Pinto>

=head1 ACKNOWLEDGMENTS

Derived from L<Bash::Completion::Plugins::perlbrew> by Rob Hoelz.

=begin comment

=over

=item should_activate

=item complete

=back

=end comment

=cut
