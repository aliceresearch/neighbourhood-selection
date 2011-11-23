class Gamma

  LOG4 = Math.log(4.0)
  SG_MAGICCONST = 1.0 + Math.log(4.5)

  def initialize
    @random = Random.new 1337

  end


  def gvariate(alpha, beta)
  	"""Gamma distribution.  Not the gamma function!
  	Conditions on the parameters are alpha > 0 and beta > 0.
  	The probability distribution function is:
  							x ** (alpha - 1) * math.exp(-x / beta)
  				pdf(x) =  --------------------------------------
  							math.gamma(alpha) * beta ** alpha
  	"""
  	# alpha > 0, beta > 0, mean is alpha*beta, variance is alpha*beta**2
  	# Warning: a few older sources define the gamma distribution in terms
  	# of alpha > -1.0
  	if alpha <= 0.0 or beta <= 0.0
  		raise 'gamma: alpha and beta must be > 0.0'
    end


  	if alpha > 1.0
  		# Uses R.C.H. Cheng, "The generation of Gamma
  		# variables with non-integral shape parameters",
  		# Applied Statistics, (1977), 26, No. 1, p71-74
  		ainv = Math.sqrt(2.0 * alpha - 1.0)
  		bbb = alpha - LOG4
  		ccc = alpha + ainv
		
  		while 1
  			u1 = @random.rand
			
  			if not ((1e-7 < u1) and (u1 < 0.9999999))
  				continue
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
  			u = @random.random()
  		end
		
  		return -Math.log(u) * beta
  	else	# alpha is between 0 and 1 (exclusive)
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

g=Gamma.new
1000000.times { puts g.gvariate(2,1) }
