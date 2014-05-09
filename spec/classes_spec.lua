local luafsm = require("luafsm")

describe("classes", function()
	
	it("prototype based state machine", function()
		local my_fsm = {}
		local prototype = {}

		function my_fsm.new()
			local t = {
				counter = 42,
			}
			setmetatable(t, {__index = prototype})
			t:startup()
			return t
		end

		function prototype:onwarn()
			self.counter = self.counter + 1
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

		assert.equals(42, a.counter)
		assert.equals(42, b.counter)

		a:warn()

		assert.equals('yellow', a.current)
		assert.equals('green', b.current)

		assert.equals(43, a.counter)
		assert.equals(42, b.counter)

		assert.truthy(rawget(a, "current"))
		assert.truthy(rawget(b, "current"))
		assert.falsy(rawget(a, "warn"))
		assert.falsy(rawget(b, "warn"))
		assert.equals(a.warn, b.warn, prototype.warn)
	end)

	it("github.com/jakesgordon/javascript-state-machine issue#19", function()
		local Foo = {}
		local prototype = {}

		function Foo.new()
			local t = {
				counter = 7,
			}
			setmetatable(t, {__index = prototype})
			t:initFSM()
			return t
		end

		function prototype:onenterready()
			self.counter = self.counter + 1
		end

		function prototype:onenterrunning()
			self.counter = self.counter + 1
		end

		local fsm = luafsm.create {
			target = prototype,
			initial = { state = 'ready', event = 'initFSM', defer = true }, -- unfortunately, trying to apply an IMMEDIATE initial state wont work on prototype based FSM, it MUST be deferred and called in the constructor for each instance
			events = {
				{ name = 'execute', from = 'ready',   to = 'running'},
				{ name = 'abort',   from = 'running', to = 'ready'  },
			},
		}

		local a = Foo.new()
		local b = Foo.new()

		assert.equals('ready', a.current)
		assert.equals('ready', b.current)

		-- start with correct counter 7 (from constructor) + 1 (from onenterready)
		assert.equals(8, a.counter)
		assert.equals(8, b.counter)

		a:execute()

		assert.equals('running', a.current)
		assert.equals('ready', b.current)

		assert.equals(9, a.counter)
		assert.equals(8, b.counter)
	end)
end)