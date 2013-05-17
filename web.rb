require 'sinatra'
require 'haml'

get '/' do
	haml :sliceSampling
end
