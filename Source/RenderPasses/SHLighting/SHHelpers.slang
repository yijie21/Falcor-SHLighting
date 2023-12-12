#include "Utils/HostDeviceShared.slangh"

uint SHTerms(uint lmax)
{
    return (lmax + 1) * (lmax + 1);
}

void accumShProjection(float3 direction, float value, out float SHcoeffs[9])
{
    for (uint i = 0; i < 9; i++)
        SHcoeffs[i] = 0;

    float x = direction.x;
    float y = direction.y;
    float z = direction.z;
    float x2 = x * x;
    float y2 = y * y;
    float z2 = z * z;
    float x3 = x2 * x;
    float y3 = y2 * y;
    float z3 = z2 * z;
    float x4 = x2 * x2;
    float y4 = y2 * y2;
    float z4 = z2 * z2;
    float x5 = x2 * x3;
    float y5 = y2 * y3;
    float z5 = z2 * z3;
    float x6 = x3 * x3;
    float y6 = y3 * y3;
    float z6 = z3 * z3;
    float x8 = x6 * x2;
    float y8 = y6 * y2;
    float z8 = z6 * z2;

    float cos_term = value;

    SHcoeffs[0] += cos_term * 0.282095;
    
    SHcoeffs[1] += cos_term * (0.488603 * y);
    SHcoeffs[2] += cos_term * (0.488603 * z);
    SHcoeffs[3] += cos_term * (0.488603 * x);

    SHcoeffs[4] += cos_term * (1.092548 * x * y);
    SHcoeffs[5] += cos_term * (1.092548 * y * z);
    SHcoeffs[6] += cos_term * (0.315392 * (3 * z * z - 1));
    SHcoeffs[7] += cos_term * (1.092548 * x * z);
    SHcoeffs[8] += cos_term * (0.546274 * (x * x - y * y));

    return;

    SHcoeffs[9] += cos_term * (0.590043 * (3 * x * x - y * y) * y);
    SHcoeffs[10] += cos_term * (2.89061 * x * y * z);
    SHcoeffs[11] += cos_term * (0.457046 * y * (5 * z * z - 1));
    SHcoeffs[12] += cos_term * (0.373176 * (5 * z * z * z - 3 * z));
    SHcoeffs[13] += cos_term * (0.457046 * x * (5 * z * z - 1));
    SHcoeffs[14] += cos_term * (1.445307 * (x * x - y * y) * z);
    SHcoeffs[15] += cos_term * (0.590043 * (x * x - 3 * y * y) * x);

    SHcoeffs[16] += cos_term * (2.503342 * (x * y * (x * x - y * y)));
    SHcoeffs[17] += cos_term * (1.770131 * (3 * x * x - y * y) * y * z);
    SHcoeffs[18] += cos_term * (0.946175 * x * y * (7 * z * z - 1));
    SHcoeffs[19] += cos_term * (0.669046 * y * z * (7 * z * z - 3));
    SHcoeffs[20] += cos_term * (0.105786 * (35 * z4 - 30 * z * z + 3));
    SHcoeffs[21] += cos_term * (0.669046 * x * z * (7 * z * z - 3));
    SHcoeffs[22] += cos_term * (0.473087 * (x * x - y * y) * (7 * z * z - 1));
    SHcoeffs[23] += cos_term * (1.770131 * (x * x - 3 * y * y) * x * z);
    SHcoeffs[24] += cos_term * (0.625836 * ((x * x) * (x * x - 3 * y * y) - y * y * (3 * x * x - y * y)));


    // L = 5;
    SHcoeffs[25] += cos_term * (0.6563820568401701 * y * (5. * x4 - 10. * x2 * y2 + y4));
    SHcoeffs[26] += cos_term * (8.302649259524166 * x * (x - 1. * y) * y * (x + y) * z);
    SHcoeffs[27] += cos_term * (0.4892382994352504 * (3. * x2 * y - 1. * y3) * (-1. + 9. * z2));
    SHcoeffs[28] += cos_term * (-4.793536784973324 * x * y * z * (1. - 3. * z2));
    SHcoeffs[29] += cos_term * (0.45294665119569694 * y * (1. - 14. * z2 + 21. * z4));
    SHcoeffs[30] += cos_term * (0.1169503224534236 * z * (15. - 70. * z2 + 63. * z4));
    SHcoeffs[31] += cos_term * (0.45294665119569694 * x * (1. - 14. * z2 + 21. * z4));
    SHcoeffs[32] += cos_term * (2.396768392486662 * (x - 1. * y) * (x + y) * z * (-1. + 3. * z2));
    SHcoeffs[33] += cos_term * (0.4892382994352504 * x * (x2 - 3. * y2) * (-1. + 9. * z2));
    SHcoeffs[34] += cos_term * (2.0756623148810416 * (x4 - 6. * x2 * y2 + y4) * z);
    SHcoeffs[35] += cos_term * (0.6563820568401701 * x * (x4 - 10. * x2 * y2 + 5. * y4));

    // L = 6;
    SHcoeffs[36] += cos_term * (1.3663682103838286 * x * (3. * x4 * y - 10. * x2 * y3 + 3. * y5));
    SHcoeffs[37] += cos_term * (2.366619162231752 * y * (5. * x4 - 10. * x2 * y2 + y4) * z);
    SHcoeffs[38] += cos_term * (-2.0182596029148967 * x * y * (-1. * x + y) * (x + y) * (-1. + 11. * z2));
    SHcoeffs[39] += cos_term * (0.9212052595149236 * (3. * x2 * y - 1. * y3) * z * (-3. + 11. * z2));
    SHcoeffs[40] += cos_term * (0.9212052595149236 * x * y * (1. - 18. * z2 + 33. * z4));
    SHcoeffs[41] += cos_term * (0.5826213625187314 * y * z * (5. - 30. * z2 + 33. * z4));
    SHcoeffs[42] += cos_term * (0.06356920226762842 * (-5. + 21. * z2 * (5. - 15. * z2 + 11. * z4)));
    SHcoeffs[43] += cos_term * (0.5826213625187314 * x * z * (5. - 30. * z2 + 33. * z4));
    SHcoeffs[44] += cos_term * (-0.4606026297574618 * (-1. * x + y) * (x + y) * (1. - 18. * z2 + 33. * z4));
    SHcoeffs[45] += cos_term * (0.9212052595149236 * x * (x2 - 3. * y2) * z * (-3. + 11. * z2));
    SHcoeffs[46] += cos_term * (0.5045649007287242 * (x4 - 6. * x2 * y2 + y4) * (-1. + 11. * z2));
    SHcoeffs[47] += cos_term * (2.366619162231752 * x * (x4 - 10. * x2 * y2 + 5. * y4) * z);
    SHcoeffs[48] += cos_term * (0.6831841051919143 * (x6 - 15. * x4 * y2 + 15. * x2 * y4 - 1. * y6));

    // L=7;
    SHcoeffs[49] += cos_term * (-0.7071627325245962 * y * (-7. * x6 + 35. * x4 * y2 - 21. * x2 * y4 + y6));
    SHcoeffs[50] += cos_term * (5.291921323603801 * x * (3. * x4 * y - 10. * x2 * y3 + 3. * y5) * z);
    SHcoeffs[51] += cos_term * (0.5189155787202604 * y * (5. * x4 - 10. * x2 * y2 + y4) * (-1. + 13. * z2));
    SHcoeffs[52] += cos_term * (4.151324629762083 * x * (x - 1. * y) * y * (x + y) * z * (-3. + 13. * z2));
    SHcoeffs[53] += cos_term * (-0.15645893386229404 * y * (-3. * x2 + y2) * (3. - 66. * z2 + 143. * z4));
    SHcoeffs[54] += cos_term * (0.4425326924449826 * x * y * z * (15. - 110. * z2 + 143. * z4));
    SHcoeffs[55] += cos_term * (0.0903316075825173 * y * (-5. + 135. * z2 - 495. * z4 + 429. * z6));
    SHcoeffs[56] += cos_term * (0.06828427691200495 * z * (-35. + 315. * z2 - 693. * z4 + 429. * z6));
    SHcoeffs[57] += cos_term * (0.0903316075825173 * x * (-5. + 135. * z2 - 495. * z4 + 429. * z6));
    SHcoeffs[58] += cos_term * (0.2212663462224913 * (x - 1. * y) * (x + y) * z * (15. - 110. * z2 + 143. * z4));
    SHcoeffs[59] += cos_term * (0.15645893386229404 * x * (x2 - 3. * y2) * (3. - 66. * z2 + 143. * z4));
    SHcoeffs[60] += cos_term * (1.0378311574405208 * (x4 - 6. * x2 * y2 + y4) * z * (-3. + 13. * z2));
    SHcoeffs[61] += cos_term * (0.5189155787202604 * x * (x4 - 10. * x2 * y2 + 5. * y4) * (-1. + 13. * z2));
    SHcoeffs[62] += cos_term * (2.6459606618019005 * (x6 - 15. * x4 * y2 + 15. * x2 * y4 - 1. * y6) * z);
    SHcoeffs[63] += cos_term * (0.7071627325245962 * x * (x6 - 21. * x4 * y2 + 35. * x2 * y4 - 7. * y6));

    // L = 8;
    SHcoeffs[64] += cos_term * (5.831413281398639 * x * y * (x6 - 7. * x4 * y2 + 7. * x2 * y4 - 1. * y6));
    SHcoeffs[65] += cos_term * (-2.9157066406993195 * y * (-7. * x6 + 35. * x4 * y2 - 21. * x2 * y4 + y6) * z);
    SHcoeffs[66] += cos_term * (1.0646655321190852 * x * (3. * x4 * y - 10. * x2 * y3 + 3. * y5) * (-1. + 15. * z2));
    SHcoeffs[67] += cos_term * (3.449910622098108 * y * (5. * x4 - 10. * x2 * y2 + y4) * z * (-1. + 5. * z2));
    SHcoeffs[68] += cos_term * (1.9136660990373227 * x * (x - 1. * y) * y * (x + y) * (1. - 26. * z2 + 65. * z4));
    SHcoeffs[69] += cos_term * (1.2352661552955442 * (3. * x2 * y - 1. * y3) * z * (3. - 26. * z2 + 39. * z4));
    SHcoeffs[70] += cos_term * (0.912304516869819 * x * y * (-1. + 33. * z2 - 143. * z4 + 143. * z6));
    SHcoeffs[71] += cos_term * (0.10904124589877995 * y * z * (-35. + 11. * z2 * (35. - 91. * z2 + 65. * z4)));
    SHcoeffs[72] += cos_term * (0.009086770491564996 * (35. - 1260. * z2 + 6930. * z4 - 12012. * z6 + 6435. * z8));
    SHcoeffs[73] += cos_term * (0.10904124589877995 * x * z * (-35. + 11. * z2 * (35. - 91. * z2 + 65. * z4)));
    SHcoeffs[74] += cos_term * (0.4561522584349095 * (x - 1. * y) * (x + y) * (-1. + 33. * z2 - 143. * z4 + 143. * z6));
    SHcoeffs[75] += cos_term * (1.2352661552955442 * x * (x2 - 3. * y2) * z * (3. - 26. * z2 + 39. * z4));
    SHcoeffs[76] += cos_term * (0.47841652475933066 * (x4 - 6. * x2 * y2 + y4) * (1. - 26. * z2 + 65. * z4));
    SHcoeffs[77] += cos_term * (3.449910622098108 * x * (x4 - 10. * x2 * y2 + 5. * y4) * z * (-1. + 5. * z2));
    SHcoeffs[78] += cos_term * (0.5323327660595426 * (x6 - 15. * x4 * y2 + 15. * x2 * y4 - 1. * y6) * (-1. + 15. * z2));
    SHcoeffs[79] += cos_term * (2.9157066406993195 * x * (x6 - 21. * x4 * y2 + 35. * x2 * y4 - 7. * y6) * z);
    SHcoeffs[80] += cos_term * (0.7289266601748299 * (x8 - 28. * x6 * y2 + 70. * x4 * y4 - 28. * x2 * y6 + y8));
}

