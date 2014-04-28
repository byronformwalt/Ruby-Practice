// Implemented in C++ since Ruby implementation was timing out after 16 s.

#include <iostream>
#include <math.h>
#include <vector>
using namespace std;

typedef vector<uint64_t> A;

#define BSEARCH

uint64_t get_greatest_mult(uint64_t m)
{
/*
 def greatest_mult(m)
    # Returns the greatest positive integer, q, less than or equal to m such that there exist an integer, r > 1 that satisfies q.mod(5**r) == 0.
    return nil if m < 5**2 || !m.kind_of?(Fixnum)
    r_max = (log(m)/log(5)).floor
    q = 2.upto(r_max).collect{|r| q0 = 5**r; (m/q0)*q0}.max
 end
 */
    if(m < 25)
    {
        return 0;
    }
    
    uint64_t r_max = floor(log(m)/log(5));
    uint64_t q = 0, r;
    cout << r_max << endl;
    for(r = 2;r <= r_max;r++)
    {
        uint64_t q0 = (uint64_t)pow(5,r);
        q0 = (m/q0)*q0;
        q = q0 > q ? q0 : q;
    }
    return q;
}

A count_roots(uint64_t m)
{
/*
 def count_roots(m)
    # For all positive integers i <= m, returns a hash containing the number of occurrences of each multiple which has root r of 5.
    r_counts = Hash.new(0)
    return if m < 25
    r_max = (log(m)/log(5)).floor
    2.upto(r_max) do |r|
        r_counts[r] = m/5**r
    end
 
    # Note that some of the multiples of 5**r0 are also multiples of 5**r1 for r1 > r0.  We offset these counts by subtracting counts from higher values of r.
    nr = r_counts.length
    if nr > 1
        r_counts.keys.reverse[1..-1].each do |r|
            r_counts[r] -= Hash[r_counts.find_all{|k,v| k > r}].values.inject(:+)
        end
    end
    r_counts
 end
*/
    A r_counts;
    A::iterator pos;
    if(m < 25)
    {
        return r_counts;
    }
    uint64_t r_max = floor(log(m)/log(5));
    uint64_t r, nr;
    for(r = 2;r <= r_max;r++)
    {
        r_counts.push_back(m/((uint64_t)pow(5, r)));
    }
    
    nr = r_counts.size();
    if(nr > 1)
    {
        for(pos = r_counts.end()-2;pos != r_counts.begin()-1;pos--)
        {
            uint64_t &c = *pos, delta = 0;
            A::iterator pos2;
            for(pos2 = pos + 1;pos2 != r_counts.end();pos2++)
            {
                delta += *pos2;
            }
            c -= delta;
        }
    }
    return r_counts;
}


uint64_t count_extras(A r_counts)
{
/*
def count_extras(r_counts)
    r_counts.collect do |r,count|
        (r-1)*count
    end.inject(:+)
end
*/
    uint64_t count = 0, r = 2;
    A::iterator pos;
    for(pos = r_counts.begin();pos != r_counts.end();pos++,r++)
    {
        uint64_t &c = *pos;
        count += (r-1)*c;
    }
    return count;
}

uint64_t bsearch_for_m(uint64_t n, uint64_t m_max, uint64_t m_min, uint level = 0)
{
    uint64_t m_proposed, n_extra, n_actual;

    // Start by analyzing the midpoint between m_min and m_max.
    
    if(m_max - m_min == 5)
    {
        // Terminal search condition.
        uint64_t n_actual_min, n_actual_max;
        n_actual_min = m_min/5 + count_extras(count_roots(m_min));
        n_actual_max = m_max/5 + count_extras(count_roots(m_max));
        m_proposed = n_actual_min >= n ? m_min : m_max;
        return m_proposed;
    }
    m_proposed = ((m_max + m_min)/10)*5;
    n_extra = count_extras(count_roots(m_proposed));
    n_actual = m_proposed/5 + n_extra;
    
    if(n_actual > n)
    {
        return bsearch_for_m(n, m_proposed, m_min, level + 1);
    }
    else if(n_actual < n)
    {
        return bsearch_for_m(n, m_max, m_proposed, level + 1);
    }
    else
    {
        // Nailed it.
        return m_proposed;
    }
}

void parse_input(A &test_cases)
{
    uint i,nt;
    cin >> nt;
    if(cin.eof())
    {
        exit(-1);
    }
    for(i = 0;i < nt;i++)
    {
        uint64_t v;
        cin >> v;
        test_cases.push_back(v);
    }
}


int main(int argc, const char * argv[])
{
    A r_counts;
    A::iterator iter;
    A test_cases;
    
    parse_input(test_cases);
    for(iter = test_cases.begin();iter != test_cases.end();iter++)
    {
        uint64_t n = *iter;
        uint64_t m = bsearch_for_m(n,n*5,0);
        cout << m << endl;
    }
    
    return 0;
}

