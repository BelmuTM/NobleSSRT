/*************************************************************************/
/*                  License Terms for ACES Components                    */
/*                                                                       */
/*  ACES software and tools are provided by the Academy under the        */
/*  following terms and conditions: A worldwide, royalty-free,           */
/*  non-exclusive right to copy, modify, create derivatives, and         */
/*  use, in source and binary forms, is hereby granted, subject to       */
/*  acceptance of this license. Performance of any of the                */
/*  aforementioned acts indicates acceptance to be bound by the          */
/*  following terms and conditions:                                      */
/*                                                                       */
/*  Copyright © 2014 Academy of Motion Picture Arts and Sciences         */
/*  (A.M.P.A.S.). Portions contributed by others as indicated.           */
/*  All rights reserved.                                                 */
/*                                                                       */
/*  Copies of source code, in whole or in part, must retain the          */
/*  above copyright notice, this list of conditions and the              */
/*  Disclaimer of Warranty.                                              */
/*  Use in binary form must retain the above copyright notice,           */
/*  this list of conditions and the Disclaimer of Warranty in            */
/*  the documentation and/or other materials provided with the           */
/*  distribution.                                                        */
/*  Nothing in this license shall be deemed to grant any rights          */
/*  to trademarks, copyrights, patents, trade secrets or any other       */
/*  intellectual property of A.M.P.A.S. or any contributors, except      */
/*  as expressly stated herein.                                          */
/*  Neither the name “A.M.P.A.S.” nor the name of any other              */
/*  contributors to this software may be used to endorse or promote      */
/*  products derivative of or based on this software without express     */
/*  prior written permission of A.M.P.A.S. or the contributors, as       */
/*  appropriate.                                                         */
/*  This license shall be construed pursuant to the laws of the State    */
/*  of California, and any disputes related thereto shall be subject     */
/*  to the jurisdiction of the courts therein.                           */
/*                                                                       */
/*  Disclaimer of Warranty: THIS SOFTWARE IS PROVIDED BY A.M.P.A.S.      */
/*  AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,      */
/*  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF             */
/*  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND               */
/*  NON-INFRINGEMENT ARE DISCLAIMED. IN NO EVENT SHALL A.M.P.A.S.,       */
/*  OR ANY CONTRIBUTORS OR DISTRIBUTORS, BE LIABLE FOR ANY DIRECT,       */
/*  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, RESTITUTIONARY, OR         */
/*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT    */
/*  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;      */
/*  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF        */
/*  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT            */
/*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE    */
/*  USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH     */
/*  DAMAGE.                                                              */
/*                                                                       */
/*  WITHOUT LIMITING THE GENERALITY OF THE FOREGOING, THE ACADEMY        */
/*  SPECIFICALLY DISCLAIMS ANY REPRESENTATIONS OR WARRANTIES WHATSOEVER  */
/*  RELATED TO PATENT OR OTHER INTELLECTUAL PROPERTY RIGHTS IN ACES,     */
/*  OR APPLICATIONS THEREOF, HELD BY PARTIES OTHER THAN A.M.P.A.S.,      */
/*  WHETHER DISCLOSED OR UNDISCLOSED.                                    */
/*************************************************************************/

float glowFwd(float ycIn, float glowGainIn, float glowMid) {
	if(ycIn <= 2.0 / 3.0 * glowMid) { return glowGainIn;                          }
	else if(ycIn >= 2.0 * glowMid)  { return 0.0;                                 } 
	else                            { return glowGainIn * (glowMid / ycIn - 0.5); }
}

float centerHue(float hue, float centerHue) {
	float hueCentered = hue - centerHue;
	return hueCentered < -180.0 ? hueCentered + 360.0 : hueCentered - 360.0;
}

/*
const float LIM_CYAN    = 1.147;
const float LIM_MAGENTA = 1.264;
const float LIM_YELLOW  = 1.312;

// Percentage of the core gamut to protect
// Values calculated to protect all the colors of the ColorChecker Classic 24 as given by
// ISO 17321-1 and Ohta (1997)
const float THR_CYAN    = 0.815;
const float THR_MAGENTA = 0.803;
const float THR_YELLOW  = 0.880;

// Aggressiveness of the compression curve
const float PWR = 1.2;

// Calculate compressed distance
float compress(float dist, float lim, float thr, float pwr) {
    float compressedDist;
    float scl;
    float nd;
    float p;

    if (dist < thr) {
        compressedDist = dist; // No compression below threshold
    } else {
        // Calculate scale factor for y = 1 intersect
        scl = (lim - thr) / pow(pow((1.0 - thr) / (lim - thr), -pwr) - 1.0, 1.0 / pwr);

        // Normalize distance outside threshold by scale factor
        nd = (dist - thr) / scl;
        p = pow(nd, pwr);

        compressedDist = thr + scl * nd / (pow(1.0 + p, 1.0 / pwr)); // Compress
    }
    return compressedDist;
}
*/

void rrt(inout vec3 color) {
	/*
	// Achromatic axis
    float achromaticAxis = maxOf(color);

	// Distance from the achromatic axis for each color component aka inverse RGB ratios
    vec3 dist = achromaticAxis == 0.0 ? vec3(0.0) : (achromaticAxis - color) / abs(achromaticAxis);

    // Compress distance with parameterized shaper function
    vec3 compressedDist;
    compressedDist.r = compress(dist.r, LIM_CYAN   , THR_CYAN   , PWR);
    compressedDist.g = compress(dist.g, LIM_MAGENTA, THR_MAGENTA, PWR);
    compressedDist.b = compress(dist.b, LIM_YELLOW , THR_YELLOW , PWR);

    // Recalculate RGB from compressed distance and achromatic
    color = achromaticAxis - compressedDist * abs(achromaticAxis);
	*/

	// Convert back to ACES2065-1
	color *= AP1_2_AP0_MAT;

	// --- Glow module --- //
	float saturation = rgbToSaturation(color);
	float ycIn       = rgbToYc(color);
	float s          = sigmoidShaper((saturation - 0.4) / 0.2);
	float addedGlow  = 1.0 + glowFwd(ycIn, RRT_GLOW_GAIN * s, RRT_GLOW_MID);

	color *= addedGlow;

	// --- Red modifier --- //
	float hue         = rgbToHue(color);
	float centeredHue = centerHue(hue, RRT_RED_HUE);
	float hueWeight   = cubicBasisShaper(centeredHue, RRT_RED_WIDTH);

	color.r += hueWeight * saturation * (RRT_RED_PIVOT - color.r) * (1.0 - RRT_RED_SCALE);

	color  = clamp16(max0(color) * AP0_2_AP1_MAT);			 // ACES to RGB rendering space
	color *= calcSatAdjustMatrix(RRT_SAT_FACTOR, AP1_RGB2Y); // Global desaturation

	// --- Apply the tonescale independently in rendering-space RGB --- //
	color.r = segmentedSplineC5Fwd(color.r);
	color.g = segmentedSplineC5Fwd(color.g);
	color.b = segmentedSplineC5Fwd(color.b);
}
