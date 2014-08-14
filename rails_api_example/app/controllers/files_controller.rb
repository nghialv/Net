class FilesController < ApplicationController
  def download_image
    image = MyFile.find(1)
    send_data image.data, type: 'image/png', disposition: 'inline'
  end

  def download_pdf
    pdf = MyFile.find(2)
    send_data pdf.data, type: 'application/pdf', disposition: 'inline'
  end

  def download_zip
    zip = MyFile.find(3)
    send_data zip.data, type: 'application/zip', disposition: 'inline'
  end

  def upload_image
    image = MyFile.find(1)
    image.data = request.raw_post
    image.save!
    render json: image, except: [:data]
  end

  def upload_pdf
    pdf = MyFile.find(2)
    pdf.data = request.raw_post
    pdf.save!
    render json: pdf, except: [:data]
  end

  def upload_zip
    zip = MyFile.find(3)
    zip.data = request.raw_post
    zip.save!
    render json: zip, except: [:data]
  end
end
