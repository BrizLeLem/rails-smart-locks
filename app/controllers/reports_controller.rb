require 'csv'

class ReportsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_server
  def handle
    if Rails.env.development?
      Behavior.delete_all
      Lock.delete_all
    end
    report = params[:report].open

    csv_options = { col_sep: ',', headers: :first_row }

    CSV.parse(report, csv_options) do |timestamp, lock_id, status_change, kind|
      lock = Lock.find_by_id(lock_id[1])
      if lock
        lock.status = status_change[1]
        lock.save
      else
        lock = Lock.create(id: lock_id[1], kind: kind[1], status: status_change[1])
      end

      Behavior.create(timestamp: timestamp[1], lock: lock, status_change: status_change[1])
    end
    render json: { message: "Nicely done" }
  end

  def authenticate_server
    code_name = request.headers["X-server-CodeName"]
    server = Server.find_by(code_name: code_name)
    access_token = request.headers["X-Server-Token"]
    unless server && server.access_token == access_token
      render json: { message: "Wrong Credentials"}
    end
  end
end
