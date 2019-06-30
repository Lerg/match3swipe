local camera = require('libs.camera')
local hashed = require('libs.hashed')
local _M = {}

local types = {'blue', 'green', 'orange', 'purple', 'red', 'teal'}

local last_sound_time = 0

local function gem_match_fx(self)
	go.animate(
		self.sprite_url,
		'tint',
		go.PLAYBACK_ONCE_FORWARD,
		vmath.vector4(3, 3, 3, 1),
		go.EASING_LINEAR, 0.3, 0, function()
			if camera.time - last_sound_time > 0.2 then
				msg.post('/sounds#match', 'play_sound')
				last_sound_time = camera.time
			end
			particlefx.play(self.explosion_url, function(script, url, id, state)
				if state == particlefx.EMITTER_STATE_POSTSPAWN then
					self._on_match(self)
				end
			end)
		end
	)
	go.animate(
		self.instance,
		'scale',
		go.PLAYBACK_ONCE_FORWARD,
		1.25 * vmath.vector3(self.size, self.size, 1),
		go.EASING_INQUAD, 0.3
	)
end

local function gem_match(self)
	self:match_fx()
	self.is_block = true
end

local function gem_reset(self)
	self.is_block = false
	go.set_scale(vmath.vector3(self.size, self.size, 1), self.instance)
	msg.post(self.instance, hashed.enable)
	sprite.reset_constant(self.sprite_url, 'tint')
	self.type = types[math.random(1, #types)]
	sprite.play_flipbook(self.instance, self.type)
end

local function gem_disable(self)
	msg.post(self.instance, hashed.disable)
end

local function gem_animate_position_y(self, position_y)
	self.is_block = true
	go.animate(
		self.instance,
		'position.y',
		go.PLAYBACK_ONCE_FORWARD,
		position_y,
		go.EASING_INQUAD, 0.1, 0, function()
			self.is_block = false
		end
	)
end

local function gem_animate_position(self, x, y)
	self.is_block = true
	go.animate(
		self.instance,
		'position',
		go.PLAYBACK_ONCE_FORWARD,
		vmath.vector3(x, y, 0),
		go.EASING_INQUAD, 0.1, 0, function()
			self.is_block = false
		end
	)
end

local function gem_set_position(self, x, y)
	go.set_position(vmath.vector3(x, y, 0), self.instance)
end

function _M.new(params)
	local gem = {
		match_fx = gem_match_fx,
		match = gem_match,
		reset = gem_reset,
		disable = gem_disable,
		animate_position_y = gem_animate_position_y,
		animate_position = gem_animate_position,
		set_position = gem_set_position,
		_on_match = params.on_match
	}
	local position = vmath.vector3(params.x, params.y, 0)
	local original_size = 16
	gem.size = params.size / original_size
	local scale = vmath.vector3(gem.size, gem.size, 1)
	local rotation = vmath.quat()
	gem.instance = factory.create('/assets#gem', position, rotation, nil, scale)
	gem.explosion_url = msg.url(nil, gem.instance, 'explosion')
	gem.sprite_url = msg.url(nil, gem.instance, 'sprite')
	gem:reset()
	return gem
end

return _M