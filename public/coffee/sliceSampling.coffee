class SliceSampler
  constructor: (options)->
    @P_function = options.function
    @x_value = 0.0
    @w_length = options.step_length
    @left_boundary = 0.0
    @right_boundary = 0.0

  draw: (minimum_value, maximum_value)->
    random_value = minimum_value + Math.random() * (maximum_value - minimum_value)

  step_out: (u_value)->
    r_multiplier = Math.random()
    @left_boundary = @x_value - r_multiplier * @w_length
    @right_boundary = @x_value + (1.0 - r_multiplier) * @w_length

    while @P_function(@left_boundary) > @u_value
      @left_boundary = @left_boundary - @w_length

    while @P_function(@right_boundary) > @u_value
      @right_boundary = @right_boundary + @w_length

  shrink: (x_prime)->
    if x_prime > @x_value
      @right_boundary = x_prime
    else
      @left_boundary = x_prime

  sample: (x_value)->
  	@x_value = x_value
  	u_prime = Math.random() * @P_function(@x_value)
  	@step_out(u_prime)

  	loop
      x_prime = @draw(@left_boundary, @right_boundary)
      break if @P_function(x_prime) > u_prime
      @shrink(x_prime)

    [x_prime, u_prime]

randomSign = ()->
	if Math.random() > 0.5
  	return 1.0
  return -1.0

# Slice sample one-dimensional function
# Function f
f = (x)->
	Math.exp(-1.0 * Math.pow(x, 2.0)/2.0) * (1.0 + Math.pow(Math.sin(3.0 * x), 2.0)) * (1.0 + Math.pow(Math.cos(5.0 * x), 2.0))

o = new Processing(document.getElementById('screen_OneD'))
sampleOneD = new SliceSampler({function: f, step_length: 1.0})

o.setup = ()->
  o.size(300,300)
  o.background(255,225,0)
  o.fill(255,255,255)
  o.noLoop()

o.draw = ()->
  burnin = 5000
  point = 5.0 * Math.random() * randomSign()
  for i in [1..burnin]
  	sample_point = sampleOneD.sample(point)
  	point = sample_point[0]

  count = 10000
  expectation = 0.0
  sample_expectation = 0.0
  for i in [0..count]
  	# Samples
    sample_point = sampleOneD.sample(point)
    point = sample_point[0]

    sample_expectation += sample_point[0]
    expectation += (sample_point[0] * f(sample_point[0]))

    y = 300.0 - (sample_point[1] * 70.0)
    x = sample_point[0] * 50.0 + 150.0
    o.set(x, y, o.color(255,0,0))

    # Analytic function samples

    x = 3.0 * Math.random() * randomSign()
    y = f(x)

    x = x * 50.0 + 150.0
    y = 300.0 - (y * 70.0)

    o.set(x, y, o.color(0,0,0))

  o.updatePixels()

o.setup()
o.draw()

#
# An inference example
# Who dunnit?
# Query: Given the murder weapon was the pipe, what is the probability that Alice committed the murder? 68%

murderers = ['Alice', 'Bob']
murdererPDF = (x)->
	return 0.3 if 0.0 <= x <= 1.0
	return 0.7 if 1.0 < x <= 2.0
	return 0.0

sampleEvent = (p, events, probabilities)->
	return events[index] for x, index in probabilities when p is x
	return null

weaponPDF = (x, murderer)->
	switch murderer
		when 'Alice'
			return 0.03 if 0.0 <= x <= 1.0
			return 0.97 if 1.0 < x <= 2.0
			return 0.0
		when 'Bob'
			return 0.2 if 0.0 <= x <= 1.0
			return 0.8 if 1.0 < x <= 2.0
			return 0.0

weaponPDFA = (x)->
  weaponPDF(x, 'Alice')

weaponPDFB = (x)->
  weaponPDF(x, 'Bob')

t = new Processing(document.getElementById('Who dunnit?'))

t.setup = ()->
  t.size(300,300)
  t.background(140,140,140)
  t.stroke(0)
  t.noLoop()

t.draw = ()->
  t.loadPixels()

  sampleWho = new SliceSampler({function: murdererPDF, step_length: 1.0})
  sampleWeaponA = new SliceSampler({function: weaponPDFA, step_length: 1.0})
  sampleWeaponB = new SliceSampler({function: weaponPDFB, step_length: 1.0})

  state = {x: Math.random(), y: Math.random()}
  count = 50000
  sample_point = []
  AG = 0.0
  AP = 0.0
  BG = 0.0
  BP = 0.0
  color = t.color(255,255,255)
  results = []
  burnin = 5000

  for i in [1..count]
  	# Murderer
	  sample_point = sampleWho.sample(state.x)
	  state.x = sample_point[0]
	  who = sampleEvent(murdererPDF(state.x), ['Alice', 'Bob'], [0.3, 0.7])

	  # Weapon
	  weapon = ''
	  if who is 'Alice'
	  	sample_point = sampleWeaponA.sample(state.y)
	  	state.y = sample_point[0]
	  	weapon = sampleEvent(weaponPDFA(state.y), ['gun', 'pipe'], [0.03, 0.97])
	  else
	  	sample_point = sampleWeaponB.sample(state.y)
	  	state.y = sample_point[0]
	  	weapon = sampleEvent(weaponPDFB(state.y), ['pipe', 'gun'], [0.2, 0.8])

	  if (who is 'Alice') and (weapon is 'gun')
	  	AG += 1.0
	  	color = t.color(255,0,0) # red
	  	results.push(['Alice','gun']) if i > burnin
	  if (who is 'Alice') and (weapon is 'pipe')
	  	AP += 1.0
	  	color = t.color(0,255,0) # green
	  	results.push(['Alice','pipe']) if i > burnin
	  if (who is 'Bob') and (weapon is 'gun')
	  	BG += 1.0
	  	color = t.color(0,0,255) # blue
	  	results.push(['Bob','gun']) if i > burnin
	  if (who is 'Bob') and (weapon is 'pipe')
	  	BP += 1.0
	  	color = t.color(255,255,0) # yellow
	  	results.push(['Bob','pipe']) if i > burnin

	  t.set(Math.floor(state.x * 150.0), Math.floor(state.y * 150.0), color)
		t.updatePixels()

		# Compute conditionals
		conditionals = "<br>The probability of Alice being the murderer if a pipe was found at the scene: " + Math.floor(AP/(AP+BP) * 100.0) + '% (answer to query)'
		conditionals += "<br>The probability of Bob being the murderer if a gun was found at the scene: " + Math.floor(BG/(AG+BG) * 100.0) + '%'

		document.getElementById('results').innerHTML = conditionals

t.setup()
t.draw()

