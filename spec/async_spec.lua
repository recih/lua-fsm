local luafsm = require("luafsm")

describe("async", function()
	
	it("state transitions", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				onleavegreen  = function() return luafsm.ASYNC end,
				onleaveyellow = function() return luafsm.ASYNC end,
				onleavered    = function() return luafsm.ASYNC end,
			}
		}

		assert.equals('green', fsm.current)

		fsm:warn()       
		assert.equals('green',  fsm.current) -- should still be green because we haven't transitioned yet
		fsm:transition() 
		assert.equals('yellow', fsm.current) -- warn event should transition from green to yellow
		fsm:panic()      
		assert.equals('yellow', fsm.current) -- should still be yellow because we haven't transitioned yet
		fsm:transition() 
		assert.equals('red',    fsm.current) -- panic event should transition from yellow to red
		fsm:calm()       
		assert.equals('red',    fsm.current) -- should still be red because we haven't transitioned yet
		fsm:transition() 
		assert.equals('yellow', fsm.current) -- calm event should transition from red to yellow
		fsm:clear()      
		assert.equals('yellow', fsm.current) -- should still be yellow because we haven't transitioned yet
		fsm:transition() 
		assert.equals('green',  fsm.current) -- clear event should transition from yellow to green
	end)

	pending("state transitions with delays", function()
	end)

	it("state transition fired during onleavestate callback - immediate", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				onleavegreen  = function(self) self:transition() return luafsm.ASYNC end, -- self.transition() / self:transition() both work
				onleaveyellow = function(self) self.transition() return luafsm.ASYNC end,
				onleavered    = function(self) self:transition() return luafsm.ASYNC end,
			}
		}

		assert.equals('green', fsm.current)

		fsm:warn()  
		assert.equals(fsm.current, 'yellow') -- warn  event should transition from green  to yellow
		fsm:panic() 
		assert.equals(fsm.current, 'red')    -- panic event should transition from yellow to red
		fsm:calm()  
		assert.equals(fsm.current, 'yellow') -- calm  event should transition from red    to yellow
		fsm:clear() 
		assert.equals(fsm.current, 'green')  -- clear event should transition from yellow to green
	end)

	pending("state transition fired during onleavestate callback - with delay", function()
	end)

	it("state transition fired during onleavestate callback - but forgot to return ASYNC!", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				onleavegreen  = function(self) self:transition() --[[ return luafsm.ASYNC ]] end,
				onleaveyellow = function(self) self:transition() --[[ return luafsm.ASYNC ]] end,
				onleavered    = function(self) self:transition() --[[ return luafsm.ASYNC ]] end,
			}
		}

		assert.equals('green', fsm.current)

		fsm:warn()  
		assert.equals('yellow', fsm.current) -- warn  event should transition from green  to yellow
		fsm:panic() 
		assert.equals('red', fsm.current)    -- panic event should transition from yellow to red
		fsm:calm()  
		assert.equals('yellow', fsm.current) -- calm  event should transition from red    to yellow
		fsm:clear() 
		assert.equals('green', fsm.current)  -- clear event should transition from yellow to green
	end)

	pending("state transitions sometimes synchronous and sometimes asynchronous", function()
	end)

	it("state transition fired without completing previous transition", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				onleavegreen  = function(self) return luafsm.ASYNC end,
				onleaveyellow = function(self) return luafsm.ASYNC end,
				onleavered    = function(self) return luafsm.ASYNC end,
			}
		}

		assert.equals('green', fsm.current)

		fsm:warn()       
		assert.equals('green',  fsm.current) -- should still be green because we haven't transitioned yet
		fsm:transition() 
		assert.equals('yellow', fsm.current) -- warn event should transition from green to yellow
		fsm:panic()      
		assert.equals('yellow', fsm.current) -- should still be yellow because we haven't transitioned yet

		assert.has.errors(function() fsm:calm() end)
	end)

	it("state transition can be cancelled", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				onleavegreen  = function(self) return luafsm.ASYNC end,
				onleaveyellow = function(self) return luafsm.ASYNC end,
				onleavered    = function(self) return luafsm.ASYNC end,
			}
		}

		assert.equals('green', fsm.current)

		fsm:warn()       
		assert.equals('green',  fsm.current) -- should still be green because we haven't transitioned yet
		fsm:transition() 
		assert.equals('yellow', fsm.current) -- warn event should transition from green to yellow
		fsm:panic()      
		assert.equals('yellow', fsm.current) -- should still be yellow because we haven't transitioned yet

		assert.falsy(fsm:can('panic'))       -- but cannot panic a 2nd time because a transition is still pending

		assert.has.errors(function() fsm:panic() end)

		fsm.transition.cancel()

		assert.equals('yellow', fsm.current) -- should still be yellow because we cancelled the async transition
		assert.truthy(fsm:can('panic'))      -- can now panic again because we cancelled previous async transition

		fsm:panic()
		fsm:transition()

		assert.equals('red', fsm.current)    -- should finally be red now that we completed the async transition
	end)

	it("callbacks are ordered correctly", function()
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
				onleavegreen    = function() table.insert(called, 'onleavegreen')  return luafsm.ASYNC end,
				onleaveyellow   = function() table.insert(called, 'onleaveyellow') return luafsm.ASYNC end,
				onleavered      = function() table.insert(called, 'onleavered')    return luafsm.ASYNC end,

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
		fsm:warn()       assert.same(called, {'onbeforewarn', 'onbefore(warn)', 'onleavegreen', 'onleave(green)'})
		fsm:transition() assert.same(called, {'onbeforewarn', 'onbefore(warn)', 'onleavegreen', 'onleave(green)', 'onenteryellow', 'onenter(yellow)', 'onchange(green,yellow)', 'onafterwarn', 'onafter(warn)'})

		called = {}
		fsm:panic()      assert.same(called, {'onbeforepanic', 'onbefore(panic)', 'onleaveyellow', 'onleave(yellow)'})
		fsm:transition() assert.same(called, {'onbeforepanic', 'onbefore(panic)', 'onleaveyellow', 'onleave(yellow)', 'onenterred', 'onenter(red)', 'onchange(yellow,red)', 'onafterpanic', 'onafter(panic)'})

		called = {}
		fsm:calm()       assert.same(called, {'onbeforecalm', 'onbefore(calm)', 'onleavered', 'onleave(red)'})
		fsm:transition() assert.same(called, {'onbeforecalm', 'onbefore(calm)', 'onleavered', 'onleave(red)', 'onenteryellow', 'onenter(yellow)', 'onchange(red,yellow)', 'onaftercalm', 'onafter(calm)'})

		called = {}
		fsm:clear()      assert.same(called, {'onbeforeclear', 'onbefore(clear)', 'onleaveyellow', 'onleave(yellow)'})
		fsm:transition() assert.same(called, {'onbeforeclear', 'onbefore(clear)', 'onleaveyellow', 'onleave(yellow)', 'onentergreen', 'onenter(green)', 'onchange(yellow,green)', 'onafterclear', 'onafter(clear)'})
	end)

	it("cannot fire event during existing transition", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',  to = 'yellow' },
				{ name = 'panic', from = 'yellow', to = 'red'    },
				{ name = 'calm',  from = 'red',    to = 'yellow' },
				{ name = 'clear', from = 'yellow', to = 'green'  },
			},
			callbacks = {
				onleavegreen  = function(self) return luafsm.ASYNC end,
				onleaveyellow = function(self) return luafsm.ASYNC end,
				onleavered    = function(self) return luafsm.ASYNC end,
			}
		}

		assert.equals('green',  fsm.current     ) -- initial state should be green
		assert.equals( true,    fsm:can('warn') ) -- should be able to warn
		assert.equals( false,   fsm:can('panic')) -- should NOT be able to panic
		assert.equals( false,   fsm:can('calm') ) -- should NOT be able to calm
		assert.equals( false,   fsm:can('clear')) -- should NOT be able to clear

		fsm:warn()

		assert.equals('green',  fsm.current     ) -- should still be green because we haven't transitioned yet
		assert.equals( false,   fsm:can('warn') ) -- should NOT be able to warn  - during transition
		assert.equals( false,   fsm:can('panic')) -- should NOT be able to panic - during transition
		assert.equals( false,   fsm:can('calm') ) -- should NOT be able to calm  - during transition
		assert.equals( false,   fsm:can('clear')) -- should NOT be able to clear - during transition

		fsm:transition()

		assert.equals('yellow', fsm.current     ) -- warn event should transition from green to yellow
		assert.equals( false,   fsm:can('warn') ) -- should NOT be able to warn
		assert.equals( true,    fsm:can('panic')) -- should be able to panic
		assert.equals( false,   fsm:can('calm') ) -- should NOT be able to calm
		assert.equals( true,    fsm:can('clear')) -- should be able to clear

		fsm:panic()

		assert.equals('yellow', fsm.current     ) -- should still be yellow because we haven't transitioned yet
		assert.equals( false,   fsm:can('warn') ) -- should NOT be able to warn  - during transition
		assert.equals( false,   fsm:can('panic')) -- should NOT be able to panic - during transition
		assert.equals( false,   fsm:can('calm') ) -- should NOT be able to calm  - during transition
		assert.equals( false,   fsm:can('clear')) -- should NOT be able to clear - during transition

		fsm:transition()

		assert.equals('red',    fsm.current     ) -- panic event should transition from yellow to red
		assert.equals( false,   fsm:can('warn') ) -- should NOT be able to warn
		assert.equals( false,   fsm:can('panic')) -- should NOT be able to panic
		assert.equals( true,    fsm:can('calm') ) -- should be able to calm
		assert.equals( false,   fsm:can('clear')) -- should NOT be able to clear
	end)
end)