local luafsm = require("luafsm")

describe("basic", function()

	it("test standalone state machine", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
		}
		assert.equals('green', fsm.current)

		fsm:warn()
		assert.equals('yellow', fsm.current)
		fsm:panic()
		assert.equals('red', fsm.current)
		fsm:calm()
		assert.equals('yellow', fsm.current)
		fsm:clear()
		assert.equals('green', fsm.current)
	end)

	it("test targeted state machine", function()
		local target = { foo = 'bar' }
		local fsm = luafsm.create {
			target = target,
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
		}

		assert.equals(target, fsm)
		assert.equals('bar', target.foo)

		assert.equals('green', target.current)

		target:warn()
		assert.equals('yellow', target.current)
		target:panic()
		assert.equals('red', target.current)
		target:calm()
		assert.equals('yellow', target.current)
		target:clear()
		assert.equals('green', target.current)
	end)

	it("test can & cannot", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
			},
		}

		assert.equals('green', fsm.current)
		assert.truthy(fsm:can('warn'),     "should be able to warn from green state")
		assert.truthy(fsm:cannot('panic'), "should NOT be able to panic from green state")
		assert.truthy(fsm:cannot('calm'),  "should NOT be able to calm from green state")

		fsm:warn()
		assert.equals('yellow', fsm.current)
		assert.truthy(fsm:cannot('warn'),  "should NOT be able to warn from yellow state")
		assert.truthy(fsm:can('panic'),    "should be able to panic from yellow state")
		assert.truthy(fsm:cannot('calm'),  "should NOT be able to calm from yellow state")

		fsm:panic()
		assert.equals('red', fsm.current)
		assert.truthy(fsm:cannot('warn'),  "should NOT be able to warn from red state")
		assert.truthy(fsm:cannot('panic'), "should NOT be able to panic from red state")
		assert.truthy(fsm:can('calm'),     "should be able to calm from red state")
	end)

	it("test is", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
		}

		assert.equals('green', fsm.current)
		assert.is_true(fsm:is('green'),             "current state should match")
		assert.is_not_true(fsm:is('yellow'),        "current state should NOT match")
		assert.is_true(fsm:is{'green', 'red'},      "current state should match when included in array")
		assert.is_not_true(fsm:is{'yellow', 'red'}, "current state should NOT match when not included in array")

		fsm:warn()

		assert.equals('yellow', fsm.current)
		assert.is_not_true(fsm:is('green'),         "current state should NOT match")
		assert.is_true(fsm:is('yellow'),            "current state should match")
		assert.is_not_true(fsm:is{'green', 'red'},  "current state should NOT match when not included in array")
		assert.is_true(fsm:is{'yellow', 'red'},     "current state should match when included in array")
	end)

	it("test is_finished", function()
		local fsm = luafsm.create {
			initial = 'green', terminal = 'red',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
			},
		}

		assert.equals('green', fsm.current)
		assert.is_not_true(fsm:is_finished())

		fsm:warn()
		assert.equals('yellow', fsm.current)
		assert.is_not_true(fsm:is_finished())

		fsm:panic()
		assert.equals('red', fsm.current)
		assert.is_true(fsm:is_finished())
	end)

	it("test is_finished - without specifying terminal state", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
			},
		}

		assert.equals('green', fsm.current)
		assert.is_not_true(fsm:is_finished())

		fsm:warn()
		assert.equals('yellow', fsm.current)
		assert.is_not_true(fsm:is_finished())

		fsm:panic()
		assert.equals('red', fsm.current)
		assert.is_not_true(fsm:is_finished())
	end)

	it("test inappropriate events", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
			},
		}

		assert.equals('green', fsm.current)
		assert.has.errors(function() fsm:panic() end)
		assert.has.errors(function() fsm:calm() end)

		fsm:warn()
		assert.equals('yellow', fsm.current)
		assert.has.errors(function() fsm:warn() end)
		assert.has.errors(function() fsm:calm() end)

		fsm:panic()
		assert.equals('red', fsm.current)
		assert.has.errors(function() fsm:warn() end)
		assert.has.errors(function() fsm:panic() end)
	end)

	it("test inappropriate event handling can be customized", function()
		local fsm = luafsm.create {
			error = function(self, event, error_code, err) return error_code end,
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
			},
		}

		assert.equals('green', fsm.current)
		assert.equals(luafsm.INVALID_TRANSITION_ERROR, fsm:panic())
		assert.equals(luafsm.INVALID_TRANSITION_ERROR, fsm:calm())

		fsm:warn()
		assert.equals('yellow', fsm.current)
		assert.equals(luafsm.INVALID_TRANSITION_ERROR, fsm:warn())
		assert.equals(luafsm.INVALID_TRANSITION_ERROR, fsm:calm())

		fsm:panic()
		assert.equals('red', fsm.current)
		assert.equals(luafsm.INVALID_TRANSITION_ERROR, fsm:warn())
		assert.equals(luafsm.INVALID_TRANSITION_ERROR, fsm:panic())
	end)

	it("test event is cancelable", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
			},
		}

		assert.equals('green', fsm.current)
		
		fsm.onbeforewarn = function() return false end
		assert.equals(luafsm.CANCELLED, fsm:warn())

		assert.equals('green', fsm.current)
	end)

	it("test callbacks are ordered correctly", function()
		local called = {}
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				-- generic callbacks
				onbeforeevent   = function(self, event) table.insert(called, ('onbefore(%s)'):format(event.name))             end,
	    		onafterevent    = function(self, event) table.insert(called, ('onafter(%s)'):format(event.name))              end,
	    		onleavestate    = function(self, event) table.insert(called, ('onleave(%s)'):format(event.from))              end,
	    		onenterstate    = function(self, event) table.insert(called, ('onenter(%s)'):format(event.to))                end,
	    		onchangestate   = function(self, event) table.insert(called, ('onchange(%s,%s)'):format(event.from, event.to))end,

	    		-- specific state callbacks
				onentergreen    = function() table.insert(called, 'onentergreen')  end,
				onenteryellow   = function() table.insert(called, 'onenteryellow') end,
				onenterred      = function() table.insert(called, 'onenterred')    end,
				onleavegreen    = function() table.insert(called, 'onleavegreen')  end,
				onleaveyellow   = function() table.insert(called, 'onleaveyellow') end,
				onleavered      = function() table.insert(called, 'onleavered')    end,

				-- specific event callbacks
				onbeforewarn    = function() table.insert(called, 'onbeforewarn')  end,
				onbeforepanic   = function() table.insert(called, 'onbeforepanic') end,
				onbeforecalm    = function() table.insert(called, 'onbeforecalm')  end,
				onbeforeclear   = function() table.insert(called, 'onbeforeclear') end,
				onafterwarn     = function() table.insert(called, 'onafterwarn')   end,
				onafterpanic    = function() table.insert(called, 'onafterpanic')  end,
				onaftercalm     = function() table.insert(called, 'onaftercalm')   end,
				onafterclear    = function() table.insert(called, 'onafterclear')  end,
			}
		}

		called = {}
		fsm:warn()
		assert.same({
			'onbeforewarn',
			'onbefore(warn)',
			'onleavegreen',
			'onleave(green)',
			'onenteryellow',
			'onenter(yellow)',
			'onchange(green,yellow)',
			'onafterwarn',
			'onafter(warn)'
		}, called)

		called = {}
		fsm:panic()
		assert.same({
			'onbeforepanic',
			'onbefore(panic)',
			'onleaveyellow',
			'onleave(yellow)',
			'onenterred',
			'onenter(red)',
			'onchange(yellow,red)',
			'onafterpanic',
			'onafter(panic)'
		}, called)

		called = {}
		fsm:calm()
		assert.same({
			'onbeforecalm',
			'onbefore(calm)',
			'onleavered',
			'onleave(red)',
			'onenteryellow',
			'onenter(yellow)',
			'onchange(red,yellow)',
			'onaftercalm',
			'onafter(calm)'
		}, called)

		called = {}
		fsm:clear()
		assert.same({
			'onbeforeclear',
			'onbefore(clear)',
			'onleaveyellow',
			'onleave(yellow)',
			'onentergreen',
			'onenter(green)',
			'onchange(yellow,green)',
			'onafterclear',
			'onafter(clear)'
		}, called)
	end)

	it("test callbacks are ordered correctly - for same state transition", function()
		local called = {}
		local fsm = luafsm.create {
			initial = 'waiting',
			events = {
				{ name = 'data',    from = {'waiting', 'receipt'}, to = 'receipt' },
				{ name = 'nothing', from = {'waiting', 'receipt'}, to = 'waiting' },
				{ name = 'error',   from = {'waiting', 'receipt'}, to = 'error'   }, -- bad practice to have event name same as state name - but I'll let it slide just this once
			},
			callbacks = {
				-- generic callbacks
				onbeforeevent   = function(self, event) table.insert(called, ('onbefore(%s)'):format(event.name))             end,
	    		onafterevent    = function(self, event) table.insert(called, ('onafter(%s)'):format(event.name))              end,
	    		onleavestate    = function(self, event) table.insert(called, ('onleave(%s)'):format(event.from))              end,
	    		onenterstate    = function(self, event) table.insert(called, ('onenter(%s)'):format(event.to))                end,
	    		onchangestate   = function(self, event) table.insert(called, ('onchange(%s,%s)'):format(event.from, event.to))end,

				-- specific state callbacks
				onenterwaiting  = function() table.insert(called, 'onenterwaiting')  end,
				onenterreceipt  = function() table.insert(called, 'onenterreceipt')  end,
				onentererror    = function() table.insert(called, 'onentererror')    end,
				onleavewaiting  = function() table.insert(called, 'onleavewaiting')  end,
				onleavereceipt  = function() table.insert(called, 'onleavereceipt')  end,
				onleaveerror    = function() table.insert(called, 'onleaveerror')    end,

				-- specific event callbacks
				onbeforedata    = function() table.insert(called, 'onbeforedata')    end,
				onbeforenothing = function() table.insert(called, 'onbeforenothing') end,
				onbeforeerror   = function() table.insert(called, 'onbeforeerror')   end,
				onafterdata     = function() table.insert(called, 'onafterdata')     end,
				onafternothing  = function() table.insert(called, 'onafternothing')  end,
				onaftereerror   = function() table.insert(called, 'onaftererror')    end,
			}
		}

		called = {}
		fsm:data()
		assert.same({
			'onbeforedata',
			'onbefore(data)',
			'onleavewaiting',
			'onleave(waiting)',
			'onenterreceipt',
			'onenter(receipt)',
			'onchange(waiting,receipt)',
			'onafterdata',
			'onafter(data)'
		}, called)

		called = {}
		fsm:data()			-- same-state transition
		assert.same({		-- so NO enter/leave/change state callbacks are fired
			'onbeforedata',
			'onbefore(data)',
			'onafterdata',
			'onafter(data)'
		}, called)

		called = {}
		fsm:data()			-- same-state transition
		assert.same({		-- so NO enter/leave/change state callbacks are fired
			'onbeforedata',
			'onbefore(data)',
			'onafterdata',
			'onafter(data)'
		}, called)

		called = {}
		fsm:nothing()
		assert.same({
			'onbeforenothing',
			'onbefore(nothing)',
			'onleavereceipt',
			'onleave(receipt)',
			'onenterwaiting',
			'onenter(waiting)',
			'onchange(receipt,waiting)',
			'onafternothing',
			'onafter(nothing)'
		}, called)
	end)

	it("test callback arguments are correct", function()
		local expected = { event = { name = 'startup', from = 'none', to = 'green'} }	-- first expected callback

		local function verify_expected(event, a, b, c)
			assert.same(expected.event, event)
			assert.equals(expected.a, a)
			assert.equals(expected.b, b)
			assert.equals(expected.c, c)
		end

		fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				-- generic callbacks
				onbeforeevent   = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
	    		onafterevent    = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
	    		onleavestate    = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
	    		onenterstate    = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
	    		onchangestate   = function(self, event, a, b, c) verify_expected(event, a, b, c) end,

				-- specific state callbacks
				onenterwaiting  = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onenterreceipt  = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onentererror    = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onleavewaiting  = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onleavereceipt  = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onleaveerror    = function(self, event, a, b, c) verify_expected(event, a, b, c) end,

				-- specific event callbacks
				onbeforedata    = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onbeforenothing = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onbeforeerror   = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onafterdata     = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onafternothing  = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
				onaftereerror   = function(self, event, a, b, c) verify_expected(event, a, b, c) end,
			}
		}

		expected = { event = {name = 'warn', from = 'green', to = 'yellow'}, a = 1, b = 2, c = 3 }
		fsm:warn(1, 2, 3)

		expected = { event = {name = 'panic', from = 'yellow', to = 'red'}, a = 4, b = 5, c = 6 }
		fsm:panic(4, 5, 6)

		expected = { event = {name = 'calm', from = 'red', to = 'yellow'}, a = 'foo', b = 'bar', c = nil }
		fsm:calm('foo', 'bar')

		expected = { event = {name = 'clear', from = 'yellow', to = 'green'}, a = nil, b = nil, c = nil }
		fsm:clear()
	end)

	it("exceptions in caller-provided callbacks are not swallowed", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
			},
			callbacks = {
				onenteryellow = function() error('oops') end,
			}
		}

		assert.equals('green', fsm.current)
		assert.has.errors(function() fsm:warn() end)
	end)

	it("no-op transitions", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'noop',  from = 'green',  --[[ no-op ]] },
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
		}

		assert.equals('green', fsm.current)
		assert.is_true(fsm:can('noop'))
		assert.is_true(fsm:can('warn'))

		fsm:noop()
		assert.equals('green', fsm.current)
		fsm:warn()
		assert.equals('yellow', fsm.current)

		assert.is_not_true(fsm:can('noop'))
		assert.is_not_true(fsm:can('warn'))
	end)

	it("wildcard 'from' allows event from any state", function()
		local fsm = luafsm.create {
			initial = 'stopped',
			events = {
				{ name = 'prepare', from = 'stopped',      to = 'ready'   },
				{ name = 'start',   from = 'ready',        to = 'running' },
				{ name = 'resume',  from = 'paused',       to = 'running' },
				{ name = 'pause',   from = 'running',      to = 'paused'  },
				{ name = 'stop',    from = '*',            to = 'stopped' }
			},
		}

		assert.equals('stopped', fsm.current)

		fsm:prepare()
		assert.equals('ready', fsm.current)
		fsm:stop()
		assert.equals('stopped', fsm.current)

		fsm:prepare()
		assert.equals('ready', fsm.current)
		fsm:start()
		assert.equals('running', fsm.current)
		fsm:stop()
		assert.equals('stopped', fsm.current)

		fsm:prepare()
		assert.equals('ready', fsm.current)
		fsm:start()
		assert.equals('running', fsm.current)
		fsm:pause()
		assert.equals('paused', fsm.current)
		fsm:stop()
		assert.equals('stopped', fsm.current)
	end)

	it("wildcard 'from' allows event from any state", function()
		local fsm = luafsm.create {
			initial = 'stopped',
			events = {
				{ name = 'prepare', from = 'stopped',      to = 'ready'   },
				{ name = 'start',   from = 'ready',        to = 'running' },
				{ name = 'resume',  from = 'paused',       to = 'running' },
				{ name = 'pause',   from = 'running',      to = 'paused'  },
				{ name = 'stop',  --[[ any from state ]]   to = 'stopped' }
			},
		}

		assert.equals('stopped', fsm.current)

		fsm:prepare()
		assert.equals('ready', fsm.current)
		fsm:stop()
		assert.equals('stopped', fsm.current)

		fsm:prepare()
		assert.equals('ready', fsm.current)
		fsm:start()
		assert.equals('running', fsm.current)
		fsm:stop()
		assert.equals('stopped', fsm.current)

		fsm:prepare()
		assert.equals('ready', fsm.current)
		fsm:start()
		assert.equals('running', fsm.current)
		fsm:pause()
		assert.equals('paused', fsm.current)
		fsm:stop()
		assert.equals('stopped', fsm.current)
	end)

	it("event return values", function()
		local fsm = luafsm.create {
			initial = 'stopped',
			events = {
				{ name = 'prepare', from = 'stopped', to = 'ready'   },
				{ name = 'fake',    from = 'ready',   to = 'running' },
				{ name = 'start',   from = 'ready',   to = 'running' },
			},
			callbacks = {
				onbeforefake = function(self, event) return false end,        -- this event will be cancelled
				onleaveready = function(self, event) return luafsm.ASYNC end, -- this state transition is ASYNC
			}
		}

		assert.equals('stopped', fsm.current)

		assert.equals(luafsm.SUCCEEDED, fsm:prepare())
		assert.equals('ready', fsm.current)

		assert.equals(luafsm.CANCELLED, fsm:fake())
		assert.equals('ready', fsm.current)

		assert.equals(luafsm.PENDING, fsm:start())
		assert.equals('ready', fsm.current)

		assert.equals(luafsm.SUCCEEDED, fsm:transition())
		assert.equals('running', fsm.current)
	end)
end)