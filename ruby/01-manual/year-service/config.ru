# SPDX-License-Identifier: Apache-2.0

require "bundler/setup"
Bundler.require

class App < Grape::API
  format :txt

  get :year do
    sleep rand(0..0.005)
    (2015..2020).to_a.sample
  end
end
if

          else
end
run App
