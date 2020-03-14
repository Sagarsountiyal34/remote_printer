
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  attr_writer :login
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :authentication_keys => {login: true}

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :phone_number, type: String, default: ""
  field :role,              type: String, default: "user"
  field :phone_otp, type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time


  has_many :upload_documents, dependent: :destroy
  has_many :groups, dependent: :destroy
  has_one :note, dependent: :destroy

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  ## Confirmable
  field :confirmation_token,   type: String
  field :confirmed_at,         type: Time
  field :confirmation_sent_at, type: Time
  field :unconfirmed_email,    type: String # Only if using reconfirmable
  field :confirmable_otp,    type: String # Only if using reconfirmable
  field :otp_confirmed,      type: Boolean, default: false



  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  before_create :generate_confirmable_otp
  after_create :send_otp_mail
  

  def generate_confirmable_otp
    self.confirmable_otp =  rand(10 ** 5)
  end

  def send_otp_mail
    ExampleMailer.send_otp_email(self).deliver_now if self.email.present?
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      self.any_of({ :phone_number =>  /^#{::Regexp.escape(login)}$/i }, { :email =>  /^#{::Regexp.escape(login)}$/i }).first
    else
      super
    end
  end

  def send_reset_password_instructions_email_sms(password_url)
      raw_token = set_reset_password_token
      self.email.present? ? send_reset_password_instructions_by_email(raw_token) : send_reset_password_instructions_by_sms(raw_token,password_url)
  end
    # function to handle user's login via email or username
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login).downcase
      where(conditions).where('$or' => [ {:phone_number => /^#{::Regexp.escape(login)}$/i}, {:email => /^#{::Regexp.escape(login)}$/i} ]).first
    else
      where(conditions).first
    end
  end

  def get_total_group
    total_group = ''
    if self.groups.present?
          total_group = self.groups.length
    end
  end
  def get_total_progress_group
    if self.groups.present?
          total_group = self.groups.where(:status.in => ['ready_for_print', 'sent_for_printing', 'processing','failed'])
          total_group.present?  ? total_group.length : ''
    end
  end

  def check_if_any_group_ready_for_payment
    self.groups.find_by(:status => 'ready_for_payment')
  end

  def is_user?
    self.role == 'user'
  end

  def is_admin?
    self.role == 'admin'
  end
  def email_required?
    false
  end


  def login
    @login || self.phone_number || self.email
  end
  private
  def send_reset_password_instructions_by_email(raw_token)
    send_reset_password_instructions_notification(raw_token)
  end

  def send_reset_password_instructions_by_sms(raw_token,password_url)
    PhoneMessageSender.send_password_instruction(self, password_url,raw_token)
  end

end




