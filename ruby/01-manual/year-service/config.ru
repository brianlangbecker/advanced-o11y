# SPDX-License-Identifier: Apache-2.0

require "bundler/setup"
Bundler.require

class App < Grape::API
  format :txt

  get :year do
    current_year = Time.now.year
    sleep rand(0..0.005)
    (2015..current_year).to_a.sample
  end
end

run App
