local luafsm = require("luafsm")

describe("special initialization options", function()
	local target = {}
	local fsm = nil

	setup(function()
		target.called = {}
	    target.onbeforeevent   = function(self, event) table.insert(target.called, ('onbefore(%s)'):format(event.name))             end
	    target.onafterevent    = function(self, event) table.insert(target.called, ('onafter(%s)'):format(event.name))              end
	    target.onleavestate    = function(self, event) table.insert(target.called, ('onleave(%s)'):format(event.from))              end
	    target.onenterstate    = function(self, event) table.insert(target.called, ('onenter(%s)'):format(event.to))                end
	    target.onchangestate   = function(self, event) table.insert(target.called, ('onchange(%s,%s)'):format(event.from, event.to))end
	    target.onbeforeinit    = function()            table.insert(target.called, "onbeforeinit")                                  end
	    target.onafterinit     = function()            table.insert(target.called, "onafterinit")                                   end
	    target.onbeforestartup = function()            table.insert(target.called, "onbeforestartup")                               end
	    target.onafterstartup  = function()            table.insert(target.called, "onafterstartup")                                end
	    target.onbeforepanic   = function()            table.insert(target.called, "onbeforepanic")                                 end
	    target.onafterpanic    = function()            table.insert(target.called, "onafterpanic")                                  end
	    target.onbeforecalm    = function()            table.insert(target.called, "onbeforecalm")                                  end
	    target.onaftercalm     = function()            table.insert(target.called, "onaftercalm")                                   end
	    target.onenternone     = function()            table.insert(target.called, "onenternone")                                   end
	    target.onentergreen    = function()            table.insert(target.called, "onentergreen")                                  end
	    target.onenterred      = function()            table.insert(target.called, "onenterred")                                    end
	    target.onleavenone     = function()            table.insert(target.called, "onleavenone")                                   end
	    target.onleavegreen    = function()            table.insert(target.called, "onleavegreen")                                  end
	    target.onleavered      = function()            table.insert(target.called, "onleavered")                                    end
	end)

	before_each(function()
		target.called = {}
	end)

	it("can initial state defaults to 'none'", function()
		local fsm = luafsm.create {
			target = target,
			events = {
				{ name = 'panic', from = 'green', to = 'red'   },
    			{ name = 'calm',  from = 'red',   to = 'green' },
			},
		}
		assert.equals('none', fsm.current)
		assert.same({}, fsm.called)
	end)

	it("can initial state can be specified", function()
		local fsm = luafsm.create {
			target = target,
			initial = 'green',
			events = {
				{ name = 'panic', from = 'green', to = 'red'   },
    			{ name = 'calm',  from = 'red',   to = 'green' },
			},
		}

		assert.equals('green', fsm.current)
		assert.same({
			"onbeforestartup",
		    "onbefore(startup)",
		    "onleavenone",
		    "onleave(none)",
		    "onentergreen",
		    "onenter(green)",
		    "onchange(none,green)",
		    "onafterstartup",
		    "onafter(startup)"
		}, fsm.called)
	end)

	it("startup event name can be specified", function()
		local fsm = luafsm.create {
			target = target,
			initial = { state = 'green', event = 'init' },
			events = {
				{ name = 'panic', from = 'green', to = 'red'   },
    			{ name = 'calm',  from = 'red',   to = 'green' },
			},
		}

		assert.equals('green', fsm.current)
		assert.same({
			"onbeforeinit",
		    "onbefore(init)",
		    "onleavenone",
		    "onleave(none)",
		    "onentergreen",
		    "onenter(green)",
		    "onchange(none,green)",
		    "onafterinit",
		    "onafter(init)"
		}, fsm.called)
	end)

	it("startup event can be deferred", function()
		local fsm = luafsm.create {
			target = target,
			initial = { state = 'green', event = 'init', defer = true },
			events = {
				{ name = 'panic', from = 'green', to = 'red'   },
    			{ name = 'calm',  from = 'red',   to = 'green' },
			},
		}

		assert.equals('none', fsm.current)
		assert.same({}, fsm.called)

		fsm:init()

		assert.same({
			"onbeforeinit",
		    "onbefore(init)",
		    "onleavenone",
		    "onleave(none)",
		    "onentergreen",
		    "onenter(green)",
		    "onchange(none,green)",
		    "onafterinit",
		    "onafter(init)"
		}, fsm.called)
	end)
end)