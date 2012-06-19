class Gamma

  LOG4 = Math.log(4.0)
  SG_MAGICCONST = 1.0 + Math.log(4.5)

  # Creates a new Gamma random number generating object.
  # By default, it will create a random number generator for its own use.
  # If you prefer, you can pass in a random number generator
  # (i.e. an object of type Random) and it will use that instead.
  #
  def initialize(random = (Random.new 1337))
      @random = random

  end


  # Gamma distribution.  Not the gamma function!
  # Conditions on the parameters are alpha > 0 and beta > 0.
  # The probability distribution function is:
  #
  #             x ** (alpha - 1) * math.exp(-x / beta)
  #   pdf(x) =  --------------------------------------
  #               math.gamma(alpha) * beta ** alpha
  #
  # The mean is alpha*beta, variance is alpha*beta**2.
  #
  # This code adapted from the Python standard library by Arjun Chandra and
  # Peter Lewis.
  #
  def gamma_variate(alpha, beta)

    # Sanity check on parameters
    if alpha <= 0.0 or beta <= 0.0
      raise 'gamma: alpha and beta must be > 0.0'

    end

    # There are three cases here, dealt with sequentially:
    # a) alpha > 1
    # b) alpha = 1
    # c) 0 < alpha < 1

    if alpha > 1.0
      # Uses R.C.H. Cheng, "The generation of Gamma variables with non-integral
      # shape parameters", Applied Statistics, (1977), 26, No. 1, p71-74
      ainv = Math.sqrt(2.0 * alpha - 1.0)
      bbb = alpha - LOG4
      ccc = alpha + ainv

      while 1
        u1 = @random.rand

        if not ((1e-7 < u1) and (u1 < 0.9999999))
          next
        end

        u2 = 1.0 - @random.rand
        v = Math.log(u1/(1.0-u1))/ainv
        x = alpha*Math.exp(v)
        z = u1*u1*u2
        r = bbb+ccc*v-x

        if r + SG_MAGICCONST - 4.5*z >= 0.0 or r >= Math.log(z)
          return x * beta
        end

      end

    elsif alpha == 1.0
      # expovariate(1)
      u = @random.rand

      while u <= 1e-7
        u = @random.rand
      end

      return -Math.log(u) * beta

    else  # alpha is between 0 and 1 (exclusive)
      # Uses ALGORITHM GS of Statistical Computing - Kennedy & Gentle
      while 1
        u = @random.rand
        b = (Math.e + alpha)/Math.e
        p = b*u

        if p <= 1.0
          x = p ** (1.0/alpha)
        else
          x = -Math.log((b-p)/alpha)
        end

        u1 = @random.rand
        if p > 1.0
          if u1 <= x ** (alpha - 1.0)
            break
          end
        elsif u1 <= Math.exp(-x)
          break
        end
      end

      return x * beta

    end

  end


end

