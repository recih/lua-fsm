local luafsm = require("luafsm")

describe("advanced", function()
	
	it("multiple 'from' states for the same event", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',             to = 'yellow' },
				{ name = 'panic', from = {'green', 'yellow'}, to = 'red'    },
				{ name = 'calm',  from = 'red',               to = 'yellow' },
				{ name = 'clear', from = {'yellow', 'red'},   to = 'green'  },
			},
		}

		assert.equals('green', fsm.current)

		assert.truthy(fsm:can('warn'))     -- should be able to warn from green state
		assert.truthy(fsm:can('panic'))    -- should be able to panic from green state
		assert.truthy(fsm:cannot('calm'))  -- should NOT be able to calm from green state
		assert.truthy(fsm:cannot('clear')) -- should NOT be able to clear from green state

		fsm:warn()  assert.equals('yellow',fsm.current) -- warn  event should transition from green  to yellow
		fsm:panic() assert.equals('red',   fsm.current) -- panic event should transition from yellow to red
		fsm:calm()  assert.equals('yellow',fsm.current) -- calm  event should transition from red    to yellow
		fsm:clear() assert.equals('green', fsm.current) -- clear event should transition from yellow to green

		fsm:panic() assert.equals('red',   fsm.current) -- panic event should transition from green to red
		fsm:clear() assert.equals('green', fsm.current) -- clear event should transition from red to green
	end)

	it("multiple 'to' states for the same event", function()
		local fsm = luafsm.create {
			initial = 'hungry',
			events = {
				{ name = 'eat',  from = 'hungry',                                to = 'satisfied' },
				{ name = 'eat',  from = 'satisfied',                             to = 'full'      },
				{ name = 'eat',  from = 'full',                                  to = 'sick'      },
				{ name = 'rest', from = {'hungry', 'satisfied', 'full', 'sick'}, to = 'hungry'    },
			},
		}

		assert.equals('hungry', fsm.current)

		assert.truthy(fsm:can('eat'))
		assert.truthy(fsm:can('rest'))

		fsm:eat()
		assert.equals('satisfied', fsm.current)

		fsm:eat()
		assert.equals('full', fsm.current)

		fsm:eat()
		assert.equals('sick', fsm.current)

		fsm:rest()
		assert.equals('hungry', fsm.current)
	end)

	it("no-op transitions with multiple from states", function()
		local fsm = luafsm.create {
			initial = 'green',
			events = {
				{ name = 'warn',  from = 'green',             to = 'yellow' },
				{ name = 'panic', from = {'green', 'yellow'}, to = 'red'    },
				{ name = 'noop',  from = {'green', 'yellow'}               }, -- NOTE = 'to' not specified
				{ name = 'calm',  from = 'red',               to = 'yellow' },
				{ name = 'clear', from = {'yellow', 'red'},   to = 'green'  },
			},
		}

		assert.equals('green', fsm.current) --initial state should be green

		assert.truthy(fsm:can('warn'),     "should be able to warn from green state")
		assert.truthy(fsm:can('panic'),    "should be able to panic from green state")
		assert.truthy(fsm:can('noop'),     "should be able to noop from green state")
		assert.truthy(fsm:cannot('calm'),  "should NOT be able to calm from green state")
		assert.truthy(fsm:cannot('clear'), "should NOT be able to clear from green state")

		fsm:noop()  assert.equals('green',  fsm.current) -- noop  event should not transition
		fsm:warn()  assert.equals('yellow', fsm.current) -- warn  event should transition from green  to yellow

		assert.truthy(fsm:cannot('warn'),  "should NOT be able to warn  from yellow state")
		assert.truthy(fsm:can('panic'),    "should     be able to panic from yellow state")
		assert.truthy(fsm:can('noop'),     "should     be able to noop  from yellow state")
		assert.truthy(fsm:cannot('calm'),  "should NOT be able to calm  from yellow state")
		assert.truthy(fsm:can('clear'),    "should     be able to clear from yellow state")

		fsm:noop()  assert.equals('yellow', fsm.current) -- noop  event should not transition
		fsm:panic() assert.equals('red',    fsm.current) -- panic event should transition from yellow to red

		assert.truthy(fsm:cannot('warn'),  "should NOT be able to warn  from red state")
		assert.truthy(fsm:cannot('panic'), "should NOT be able to panic from red state")
		assert.truthy(fsm:cannot('noop'),  "should NOT be able to noop  from red state")
		assert.truthy(fsm:can('calm'),     "should     be able to calm  from red state")
		assert.truthy(fsm:can('clear'),    "should     be able to clear from red state")
	end)

	it("callbacks are called when appropriate for multiple 'from' and 'to' transitions", function()
		local called = {}
		local fsm = luafsm.create {
			initial = 'hungry',
			events = {
				{ name = 'eat',  from = 'hungry',                                to = 'satisfied' },
				{ name = 'eat',  from = 'satisfied',                             to = 'full'      },
				{ name = 'eat',  from = 'full',                                  to = 'sick'      },
				{ name = 'rest', from = {'hungry', 'satisfied', 'full', 'sick'}, to = 'hungry'    },
			},
			callbacks = {
				-- generic callbacks
				onbeforeevent    = function(self, event) table.insert(called, ('onbefore(%s)'):format(event.name))             end,
	    		onafterevent     = function(self, event) table.insert(called, ('onafter(%s)'):format(event.name))              end,
	    		onleavestate     = function(self, event) table.insert(called, ('onleave(%s)'):format(event.from))              end,
	    		onenterstate     = function(self, event) table.insert(called, ('onenter(%s)'):format(event.to))                end,
	    		onchangestate    = function(self, event) table.insert(called, ('onchange(%s,%s)'):format(event.from, event.to))end,

	    		-- specific state callbacks
				onenterhungry    = function() table.insert(called, 'onenterhungry')    end,
				onleavehungry    = function() table.insert(called, 'onleavehungry')    end,
				onentersatisfied = function() table.insert(called, 'onentersatisfied') end,
				onleavesatisfied = function() table.insert(called, 'onleavesatisfied') end,
				onenterfull      = function() table.insert(called, 'onenterfull')      end,
				onleavefull      = function() table.insert(called, 'onleavefull')      end,
				onentersick      = function() table.insert(called, 'onentersick')      end,
				onleavesick      = function() table.insert(called, 'onleavesick')      end,
				-- specific event callbacks
				onbeforeeat      = function() table.insert(called, 'onbeforeeat')      end,
				onaftereat       = function() table.insert(called, 'onaftereat')       end,
				onbeforerest     = function() table.insert(called, 'onbeforerest')     end,
				onafterrest      = function() table.insert(called, 'onafterrest')      end,
			}
		}

		called = {}
		fsm:eat()
		assert.same({
			'onbeforeeat',
			'onbefore(eat)',
			'onleavehungry',
			'onleave(hungry)',
			'onentersatisfied',
			'onenter(satisfied)',
			'onchange(hungry,satisfied)',
			'onaftereat',
			'onafter(eat)'
		}, called)

		called = {}
		fsm:eat()
		assert.same({
			'onbeforeeat',
			'onbefore(eat)',
			'onleavesatisfied',
			'onleave(satisfied)',
			'onenterfull',
			'onenter(full)',
			'onchange(satisfied,full)',
			'onaftereat',
			'onafter(eat)',
		}, called)

		called = {}
		fsm:eat()
		assert.same({
			'onbeforeeat',
			'onbefore(eat)',
			'onleavefull',
			'onleave(full)',
			'onentersick',
			'onenter(sick)',
			'onchange(full,sick)',
			'onaftereat',
			'onafter(eat)'
		}, called)

		called = {}
		fsm:rest()
		assert.same({
			'onbeforerest',
			'onbefore(rest)',
			'onleavesick',
			'onleave(sick)',
			'onenterhungry',
			'onenter(hungry)',
			'onchange(sick,hungry)',
			'onafterrest',
			'onafter(rest)'
		}, called)
	end)

	it("callbacks are called when appropriate for prototype based state machine", function()
		local my_fsm = {}
		local prototype = {
			-- generic callbacks
			onbeforeevent   = function(self, event) table.insert(self.called, ('onbefore(%s)'):format(event.name))             end,
    		onafterevent    = function(self, event) table.insert(self.called, ('onafter(%s)'):format(event.name))              end,
    		onleavestate    = function(self, event) table.insert(self.called, ('onleave(%s)'):format(event.from))              end,
    		onenterstate    = function(self, event) table.insert(self.called, ('onenter(%s)'):format(event.to))                end,
    		onchangestate   = function(self, event) table.insert(self.called, ('onchange(%s,%s)'):format(event.from, event.to))end,

    		-- specific state callbacks
			onenternone     = function(self) table.insert(self.called, 'onenternone')     end,
			onleavenone     = function(self) table.insert(self.called, 'onleavenone')     end,
			onentergreen    = function(self) table.insert(self.called, 'onentergreen')    end,
			onleavegreen    = function(self) table.insert(self.called, 'onleavegreen')    end,
			onenteryellow   = function(self) table.insert(self.called, 'onenteryellow')   end,
			onleaveyellow   = function(self) table.insert(self.called, 'onleaveyellow')   end,
			onenterred      = function(self) table.insert(self.called, 'onenterred')      end,
			onleavered      = function(self) table.insert(self.called, 'onleavered')      end,

			-- specific event callbacks
			onbeforestartup = function(self) table.insert(self.called, 'onbeforestartup') end,
			onafterstartup  = function(self) table.insert(self.called, 'onafterstartup')  end,
			onbeforewarn    = function(self) table.insert(self.called, 'onbeforewarn')    end,
			onafterwarn     = function(self) table.insert(self.called, 'onafterwarn')     end,
			onbeforepanic   = function(self) table.insert(self.called, 'onbeforepanic')   end,
			onafterpanic    = function(self) table.insert(self.called, 'onafterpanic')    end,
			onbeforeclear   = function(self) table.insert(self.called, 'onbeforeclear')   end,
			onafterclear    = function(self) table.insert(self.called, 'onafterclear')    end,
		}

		function my_fsm.new()
			local t = {
				called = {},
			}
			setmetatable(t, {__index = prototype})
			t:startup()
			return t
		end

		local fsm = luafsm.create {
			target = prototype,
			events = {
				{ name = 'startup', from = 'none',   to = 'green' },
				{ name = 'warn',    from = 'green',  to = 'yellow' },
				{ name = 'panic',   from = 'yellow', to = 'red'    },
				{ name = 'clear',   from = 'yellow', to = 'green'  },
			},
		}

		local a = my_fsm.new()
		local b = my_fsm.new()

		assert.equals('green', a.current)
		assert.equals('green', b.current)

		assert.same(a.called, {'onbeforestartup', 'onbefore(startup)', 'onleavenone', 'onleave(none)', 'onentergreen', 'onenter(green)', 'onchange(none,green)', 'onafterstartup', 'onafter(startup)'})
		assert.same(b.called, {'onbeforestartup', 'onbefore(startup)', 'onleavenone', 'onleave(none)', 'onentergreen', 'onenter(green)', 'onchange(none,green)', 'onafterstartup', 'onafter(startup)'})

		a.called = {}
		b.called = {}

		a:warn()

		assert.equals('yellow', a.current) -- maintain independent current state
		assert.equals('green',  b.current) -- maintain independent current state

		assert.same(a.called, {'onbeforewarn', 'onbefore(warn)', 'onleavegreen', 'onleave(green)', 'onenteryellow', 'onenter(yellow)', 'onchange(green,yellow)', 'onafterwarn', 'onafter(warn)'})
		assert.same(b.called, {})
	end)

end)