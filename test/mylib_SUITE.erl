-module(mylib_SUITE).
-include_lib("eunit/include/eunit.hrl").
-compile(export_all).

suite() -> [{timetrap, {seconds, 10}}].

all() -> [happy_case].

init_per_suite(Config) ->
  CtSlaveOpts = [
                 {kill_if_fail, true},
                 {monitor_master, true},
                 {init_timeout, 3000},
                 {startup_timeout, 3000},
                 {startup_functions, [{code, add_paths, [code:get_path()]}]},
                 {erlang_flags, "-setcookie " ++ atom_to_list(erlang:get_cookie())}
                ],
  {ok, SlaveNode} = ct_slave:start(slave, CtSlaveOpts),
  pong = net_adm:ping(SlaveNode),
  {ok, [tools, meck]} = rpc:call(SlaveNode, application, ensure_all_started, [meck]),
  [{slave_node, SlaveNode} | Config].

end_per_suite(Config) ->
  SlaveNode = proplists:get_value(slave_node, Config),
  ok = rpc:call(SlaveNode, application, stop, [meck]),
  ct_slave:stop(SlaveNode),
  proplists:delete(slave_node, Config).

init_per_testcase(_TestCase, Config) ->
  SlaveNode = proplists:get_value(slave_node, Config),
  ok = rpc:call(SlaveNode, meck, new, [mylib, [no_link, passthrough]]), %% (1)
  Config.

end_per_testcase(_TestCase, _Config) ->
  rpc:multicall(meck, unload, [mylib]),
  ok.

%%====================================================================
%% Test cases
%%====================================================================

happy_case(Config) ->
  SlaveNode = proplists:get_value(slave_node, Config),
  bar = rpc:call(node(), mylib, foo, []),
  bar2 = rpc:call(SlaveNode, mylib, foo2, []),
  ok.

